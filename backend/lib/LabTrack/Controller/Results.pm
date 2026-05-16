package LabTrack::Controller::Result;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

# ============================================
# GET /api/samples/:sample_id/tests
# Lists all tests assigned to a specific sample
#
# This is a "nested route" — the URL contains :sample_id
# so we're always asking "which tests belong to THIS sample?"
# It's like: GET /orders/42/items — "show me items for order 42"
# ============================================
sub list ($self) {
    my $sample_id = $self->param('sample_id');

    # First verify the sample exists before querying its tests
    my $sample = $self->db->select_one('SELECT id FROM samples WHERE id = ?', $sample_id);
    return $self->render(json => { error => 'Sample not found' }, status => 404)
        unless $sample;

    # This query JOINs three tables together:
    #
    # sample_tests (st)      — the assignment: "sample X gets test Y"
    # test_definitions (td)  — the test details: name, unit, acceptable range
    # users (u1, u2)         — who was assigned, who approved
    #
    # JOIN = "combine rows from two tables where they share a value"
    # LEFT JOIN = "combine, but still include rows even if there's no match"
    #   (a test might not be approved yet, so approved_by could be NULL)
    #
    # We alias tables with short names (st, td, u1, u2) to keep the query readable
    # u1 and u2 are the SAME users table joined twice — once for the assigned
    # technician, once for the approving analyst
    my $results = $self->db->select_all(qq{
        SELECT st.*,
               td.name as test_name, td.category, td.unit,
               td.min_range, td.max_range, td.method,
               u1.username as assigned_to_name,
               u2.username as approved_by_name
        FROM sample_tests st
        JOIN test_definitions td ON st.test_id = td.id
        LEFT JOIN users u1 ON st.assigned_to = u1.id
        LEFT JOIN users u2 ON st.approved_by = u2.id
        WHERE st.sample_id = ?
        ORDER BY td.category, td.name
    }, $sample_id);
    # qq{} is a Perl quoting mechanism — same as "" but lets you use
    # quotes inside without escaping. Useful for long SQL strings.

    $self->render(json => { data => $results, total => scalar @$results });
}

# ============================================
# POST /api/samples/:sample_id/tests
# Assign a test to a sample
#
# This is the moment a lab manager says:
# "Run a Nicotine Content test on sample LAB-2026-0003"
# It creates a row in sample_tests linking the sample to the test
# ============================================
sub assign ($self) {
    my $sample_id = $self->param('sample_id');
    my $data      = $self->req->json;

    # --- Validation: a chain of checks before we do anything ---

    # Does the sample exist?
    my $sample = $self->db->select_one('SELECT id, status FROM samples WHERE id = ?', $sample_id);
    return $self->render(json => { error => 'Sample not found' }, status => 404)
        unless $sample;

    # Did they tell us which test to assign?
    unless ($data->{test_id}) {
        return $self->render(json => { error => 'Missing required field: test_id' }, status => 400);
    }

    # Does that test definition actually exist in our system?
    my $test_def = $self->db->select_one('SELECT id FROM test_definitions WHERE id = ?', $data->{test_id});
    return $self->render(json => { error => 'Test definition not found' }, status => 404)
        unless $test_def;

    # Is this test ALREADY assigned to this sample? Prevent duplicates.
    # 409 = "Conflict" HTTP status — the resource already exists
    my $existing = $self->db->select_one(
        'SELECT id FROM sample_tests WHERE sample_id = ? AND test_id = ?',
        $sample_id, $data->{test_id}
    );
    if ($existing) {
        return $self->render(json => { error => 'This test is already assigned to this sample' }, status => 409);
    }

    try {
        my $id = $self->db->insert(
            'INSERT INTO sample_tests (sample_id, test_id, assigned_to, status)
             VALUES (?, ?, ?, ?) RETURNING id',
            $sample_id,
            $data->{test_id},
            # If no assignee specified, assign to the current logged-in user
            # $self->session('user_id') reads from the session cookie
            $data->{assigned_to} // $self->session('user_id'),
            'pending'
        );

        # --- Automatic status transition ---
        # When the first test is assigned, the sample moves from
        # "received" (sitting on the shelf) to "in_testing" (work has begun)
        # This is a STATE MACHINE pattern — objects move through defined states
        # received → in_testing → completed (or rejected)
        #
        # "eq" is Perl's string equality operator (like === for strings in JS)
        # Perl has separate operators for strings and numbers:
        #   eq, ne, lt, gt   = string comparison
        #   ==, !=, <, >     = number comparison
        # This is a Perl quirk that trips up beginners
        if ($sample->{status} eq 'received') {
            $self->db->execute(
                "UPDATE samples SET status = 'in_testing', updated_at = NOW() WHERE id = ?",
                $sample_id
            );
        }

        # Record this action in the audit log for traceability
        $self->_audit_log('assign_test', 'sample_test', $id, {
            sample_id => $sample_id,
            test_id   => $data->{test_id},
        });

        # Fetch the full record with test details to return
        my $result = $self->db->select_one(qq{
            SELECT st.*, td.name as test_name, td.unit, td.min_range, td.max_range
            FROM sample_tests st
            JOIN test_definitions td ON st.test_id = td.id
            WHERE st.id = ?
        }, $id);

        $self->render(json => { data => $result }, status => 201);
    } catch {
        $self->render(json => { error => "Failed to assign test: $_" }, status => 500);
    };
}

# ============================================
# PUT /api/sample-tests/:id
# Update a test result — enter the measured value, change status
#
# This is when a technician comes back from the lab and says:
# "The nicotine content for this sample is 12.4 mg/g"
# ============================================
sub update ($self) {
    my $id   = $self->param('id');
    my $data = $self->req->json;

    # Fetch the existing test AND its acceptable range from the definition
    # We need the range to auto-calculate pass/fail
    my $existing = $self->db->select_one(qq{
        SELECT st.*, td.min_range, td.max_range
        FROM sample_tests st
        JOIN test_definitions td ON st.test_id = td.id
        WHERE st.id = ?
    }, $id);

    return $self->render(json => { error => 'Sample test not found' }, status => 404)
        unless $existing;

    # --- Auto pass/fail calculation ---
    # If a numeric result is entered, compare it to the acceptable range
    # defined in the test definition.
    #
    # Example: Nicotine Content test has min_range=0, max_range=50
    # If the result is 12.4, that's within range → "pass"
    # If the result is 55.0, that's over the max → "fail"
    #
    # "defined()" checks if a value exists (is not undef/null)
    # We check both the new value AND the range boundaries
    my $pass_fail = $data->{pass_fail} // $existing->{pass_fail};
    if (defined $data->{result_value} && defined $existing->{min_range} && defined $existing->{max_range}) {
        my $val = $data->{result_value};
        if ($val >= $existing->{min_range} && $val <= $existing->{max_range}) {
            $pass_fail = 'pass';
        } else {
            $pass_fail = 'fail';
        }
    }

    try {
        # The CASE WHEN in SQL means:
        # "If we're entering a result value for the first time AND
        #  tested_at hasn't been set yet, set it to NOW().
        #  Otherwise keep the existing tested_at."
        # This auto-timestamps when the test was actually performed.
        $self->db->execute(
            'UPDATE sample_tests
             SET status = ?, result_value = ?, result_text = ?, pass_fail = ?,
                 tested_at = CASE WHEN ? IS NOT NULL AND tested_at IS NULL THEN NOW() ELSE tested_at END,
                 notes = ?
             WHERE id = ?',
            $data->{status}       // $existing->{status},
            $data->{result_value} // $existing->{result_value},
            $data->{result_text}  // $existing->{result_text},
            $pass_fail,
            $data->{result_value},  # this feeds the CASE WHEN check
            $data->{notes}        // $existing->{notes},
            $id
        );

        $self->_audit_log('update_result', 'sample_test', $id, {
            result_value => $data->{result_value},
            pass_fail    => $pass_fail,
            status       => $data->{status},
        });

        my $updated = $self->db->select_one(qq{
            SELECT st.*, td.name as test_name, td.unit, td.min_range, td.max_range
            FROM sample_tests st
            JOIN test_definitions td ON st.test_id = td.id
            WHERE st.id = ?
        }, $id);

        $self->render(json => { data => $updated });
    } catch {
        $self->render(json => { error => "Failed to update result: $_" }, status => 500);
    };
}

# ============================================
# POST /api/sample-tests/:id/approve
# Analyst approves a completed test result
#
# In a real lab, results must be reviewed by a second person
# before they're official. This is a REGULATORY requirement —
# the person who ran the test can't be the same person who signs off.
# This is called "four-eyes principle" or "dual control."
# ============================================
sub approve ($self) {
    my $id = $self->param('id');

    # --- Role-based access control (RBAC) ---
    # Only analysts and admins can approve. Technicians can't.
    # $self->session('role') reads the role we stored during login.
    #
    # 403 = "Forbidden" — you're logged in but don't have permission
    # (vs 401 = "Unauthorized" — you're not logged in at all)
    my $role = $self->session('role');
    unless ($role eq 'analyst' || $role eq 'admin') {
        return $self->render(json => { error => 'Only analysts and admins can approve results' }, status => 403);
    }

    my $test = $self->db->select_one('SELECT * FROM sample_tests WHERE id = ?', $id);
    return $self->render(json => { error => 'Sample test not found' }, status => 404)
        unless $test;

    # Must be completed before it can be approved
    # Can't approve something that hasn't been done yet
    unless ($test->{status} eq 'completed') {
        return $self->render(
            json   => { error => 'Can only approve completed tests' },
            status => 400
        );
    }

    # --- Four-eyes principle ---
    # The person approving can't be the same person who ran the test
    # == is Perl's numeric equality (like === for numbers in JS)
    if ($test->{assigned_to} == $self->session('user_id')) {
        return $self->render(
            json   => { error => 'Cannot approve your own test results' },
            status => 403
        );
    }

    try {
        $self->db->execute(
            'UPDATE sample_tests SET approved_by = ?, approved_at = NOW() WHERE id = ?',
            $self->session('user_id'), $id
        );

        # --- Auto-complete the sample ---
        # After approving, check: are ALL tests for this sample now approved?
        # If yes, the entire sample is done → mark it "completed"
        #
        # This is another state machine transition:
        # in_testing → completed (when all tests pass approval)
        my $sample_id = $test->{sample_id};
        my $pending = $self->db->select_one(
            'SELECT COUNT(*) as count FROM sample_tests
             WHERE sample_id = ? AND (approved_at IS NULL)',
            $sample_id
        );

        if ($pending->{count} == 0) {
            $self->db->execute(
                "UPDATE samples SET status = 'completed', updated_at = NOW() WHERE id = ?",
                $sample_id
            );
        }

        $self->_audit_log('approve_result', 'sample_test', $id, {
            sample_id => $sample_id,
        });

        my $updated = $self->db->select_one(qq{
            SELECT st.*, td.name as test_name, u.username as approved_by_name
            FROM sample_tests st
            JOIN test_definitions td ON st.test_id = td.id
            LEFT JOIN users u ON st.approved_by = u.id
            WHERE st.id = ?
        }, $id);

        $self->render(json => { data => $updated });
    } catch {
        $self->render(json => { error => "Failed to approve: $_" }, status => 500);
    };
}

# ============================================
# Helper method: write to audit log
#
# The underscore prefix (_audit_log) is a Perl convention meaning
# "this is a private/internal method, not meant to be called from outside"
# Perl doesn't enforce private methods like JS does — it's just a hint
# to other developers saying "don't call this directly"
#
# $details = {} means the parameter defaults to an empty hash if not provided
# ============================================
sub _audit_log ($self, $action, $entity_type, $entity_id, $details = {}) {
    try {
        # Mojo::JSON::encode_json converts a Perl hash into a JSON string
        # so we can store it in PostgreSQL's JSONB column
        # ?::jsonb tells PostgreSQL to treat the string as JSON data
        $self->db->execute(
            'INSERT INTO audit_log (user_id, action, entity_type, entity_id, details)
             VALUES (?, ?, ?, ?, ?::jsonb)',
            $self->session('user_id'),
            $action,
            $entity_type,
            $entity_id,
            Mojo::JSON::encode_json($details)
        );
    } catch {
        # If audit logging fails, just warn — don't crash the request
        # The main operation already succeeded, no reason to fail it
        # over a logging issue
        $self->app->log->warn("Audit log failed: $_");
    };
}

1;
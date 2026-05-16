package LabTrack::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

# ============================================
# GET /api/dashboard/stats
# Returns counts and summaries for the dashboard overview
#
# This endpoint doesn't create or modify anything — it just
# asks the database a bunch of questions and bundles the answers.
# Think of it like a manager walking around the lab asking:
# "How many samples are waiting? How many tests passed? How many need approval?"
# ============================================
sub stats ($self) {
    try {
        # --- Sample counts grouped by status ---
        # GROUP BY takes all rows and buckets them by a column
        # Result looks like: [{ status: "received", count: 3 }, { status: "in_testing", count: 2 }]
        #
        # This is like doing: samples.reduce() in JS to count by category
        my $sample_stats = $self->db->select_all(
            "SELECT status, COUNT(*) as count FROM samples GROUP BY status ORDER BY status"
        );

        # --- Total number of samples in the system ---
        my $total_samples = $self->db->select_one("SELECT COUNT(*) as count FROM samples");

        # --- Test results grouped by pass/fail ---
        # Only counts tests that have a result (pass_fail IS NOT NULL)
        # Tests still pending or in progress won't appear here
        my $test_stats = $self->db->select_all(
            "SELECT pass_fail, COUNT(*) as count FROM sample_tests
             WHERE pass_fail IS NOT NULL GROUP BY pass_fail"
        );

        # --- Tests grouped by their workflow status ---
        # pending, in_progress, completed, failed
        my $test_status = $self->db->select_all(
            "SELECT status, COUNT(*) as count FROM sample_tests GROUP BY status ORDER BY status"
        );

        # --- Samples grouped by product type ---
        # cigarette, e-liquid, smokeless, snus, etc.
        # ORDER BY count DESC puts the most common type first
        my $type_stats = $self->db->select_all(
            "SELECT sample_type, COUNT(*) as count FROM samples GROUP BY sample_type ORDER BY count DESC"
        );

        # --- Tests waiting for analyst approval ---
        # These are tests where the technician entered a result (status = completed)
        # but no analyst has signed off yet (approved_at IS NULL)
        # This number is important — a lab manager wants to know
        # how much review work is piling up
        my $awaiting_approval = $self->db->select_one(
            "SELECT COUNT(*) as count FROM sample_tests
             WHERE status = 'completed' AND approved_at IS NULL"
        );

        # --- Samples received in the last 7 days ---
        # NOW() - INTERVAL '7 days' = the date 7 days ago
        # This shows how busy the lab has been recently
        my $recent_received = $self->db->select_one(
            "SELECT COUNT(*) as count FROM samples
             WHERE received_at > NOW() - INTERVAL '7 days'"
        );

        # Bundle everything into one response
        # The React frontend will use these numbers to render
        # charts, counters, and progress bars
        #
        # Notice the structure: { data => { ... } }
        # We wrap in "data" to be consistent with other endpoints
        # and leave room for adding metadata later (like "last_updated")
        $self->render(json => {
            data => {
                total_samples     => $total_samples->{count},
                samples_by_status => $sample_stats,
                samples_by_type   => $type_stats,
                tests_by_result   => $test_stats,
                tests_by_status   => $test_status,
                awaiting_approval => $awaiting_approval->{count},
                received_last_7d  => $recent_received->{count},
            }
        });
    } catch {
        $self->render(json => { error => "Failed to load stats: $_" }, status => 500);
    };
}

# ============================================
# GET /api/dashboard/recent
# Returns recent activity from the audit log
#
# Every action (create sample, enter result, approve test) writes
# a row to the audit_log table. This endpoint returns the latest ones,
# like a "Recent Activity" feed you'd see on GitHub or Jira.
# ============================================
sub recent_activity ($self) {
    # $self->param('limit') reads ?limit=10 from the URL
    # || 20 means "if not provided or zero, default to 20"
    #
    # Note: || vs // in Perl:
    #   || = use the right side if left is FALSE (0, "", undef)
    #   // = use the right side if left is UNDEFINED (undef only)
    # Here || is fine because limit=0 doesn't make sense anyway
    my $limit = $self->param('limit') || 20;

    try {
        # Fetch the most recent audit log entries with the username
        # ORDER BY created_at DESC = newest first
        # LIMIT ? = only return this many rows
        my $activity = $self->db->select_all(qq{
            SELECT al.*, u.username
            FROM audit_log al
            LEFT JOIN users u ON al.user_id = u.id
            ORDER BY al.created_at DESC
            LIMIT ?
        }, $limit);

        $self->render(json => { data => $activity });
    } catch {
        $self->render(json => { error => "Failed to load activity: $_" }, status => 500);
    };
}

1;
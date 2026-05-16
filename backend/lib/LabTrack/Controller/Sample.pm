package LabTrack::Controller::Sample;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

# GET /api/samples
# Query params: ?status=received&type=water&page=1&limit=20&search=client
sub list ($self) {
    my $status = $self->param('status');
    my $type   = $self->param('type');
    my $search = $self->param('search');
    my $page   = $self->param('page')  || 1;
    my $limit  = $self->param('limit') || 20;
    my $offset = ($page - 1) * $limit;

    # Build dynamic query
    my @conditions;
    my @params;

    if ($status) {
        push @conditions, 's.status = ?';
        push @params, $status;
    }
    if ($type) {
        push @conditions, 's.sample_type = ?';
        push @params, $type;
    }
    if ($search) {
        push @conditions, '(s.client_name ILIKE ? OR s.sample_code ILIKE ?)';
        push @params, "%$search%", "%$search%";
    }

    my $where = @conditions ? 'WHERE ' . join(' AND ', @conditions) : '';

    # Get total count
    my $count_row = $self->db->select_one(
        "SELECT COUNT(*) as total FROM samples s $where", @params
    );

    # Get paginated results
    my $samples = $self->db->select_all(qq{
        SELECT s.*, u.username as received_by_name
        FROM samples s
        LEFT JOIN users u ON s.received_by = u.id
        $where
        ORDER BY s.created_at DESC
        LIMIT ? OFFSET ?
    }, @params, $limit, $offset);

    $self->render(json => {
        data       => $samples,
        total      => $count_row->{total},
        page       => $page + 0,  # force numeric
        limit      => $limit + 0,
        total_pages => int(($count_row->{total} + $limit - 1) / $limit),
    });
}

# GET /api/samples/:id
sub show ($self) {
    my $id = $self->param('id');

    my $sample = $self->db->select_one(
        'SELECT s.*, u.username as received_by_name
         FROM samples s
         LEFT JOIN users u ON s.received_by = u.id
         WHERE s.id = ?', $id
    );

    return $self->render(json => { error => 'Sample not found' }, status => 404)
        unless $sample;

    # Also fetch assigned tests for this sample
    my $tests = $self->db->select_all(qq{
        SELECT st.*, td.name as test_name, td.unit, td.min_range, td.max_range,
               u1.username as assigned_to_name, u2.username as approved_by_name
        FROM sample_tests st
        JOIN test_definitions td ON st.test_id = td.id
        LEFT JOIN users u1 ON st.assigned_to = u1.id
        LEFT JOIN users u2 ON st.approved_by = u2.id
        WHERE st.sample_id = ?
        ORDER BY st.created_at
    }, $id);

    $sample->{tests} = $tests;

    $self->render(json => { data => $sample });
}

# POST /api/samples
sub create ($self) {
    my $data = $self->req->json;

    # Validate required fields
    for my $field (qw(client_name sample_type)) {
        unless ($data->{$field}) {
            return $self->render(
                json   => { error => "Missing required field: $field" },
                status => 400
            );
        }
    }

    try {
        # Generate sample code: LAB-YYYY-NNNN
        my $year = (localtime)[5] + 1900;
        my $seq = $self->db->select_one(
            "SELECT COUNT(*) + 1 as next_seq FROM samples WHERE EXTRACT(YEAR FROM created_at) = ?",
            $year
        );
        my $code = sprintf("LAB-%d-%04d", $year, $seq->{next_seq});

        my $user_id = $self->session('user_id');

        my $id = $self->db->insert(
            'INSERT INTO samples (sample_code, client_name, sample_type, notes, received_by)
             VALUES (?, ?, ?, ?, ?) RETURNING id',
            $code, $data->{client_name}, $data->{sample_type},
            $data->{notes} // '', $user_id
        );

        # Audit log
        $self->_audit_log('create', 'sample', $id, { sample_code => $code });

        my $sample = $self->db->select_one('SELECT * FROM samples WHERE id = ?', $id);
        $self->render(json => { data => $sample }, status => 201);
    } catch {
        $self->render(json => { error => "Failed to create sample: $_" }, status => 500);
    };
}

# PUT /api/samples/:id
sub update ($self) {
    my $id   = $self->param('id');
    my $data = $self->req->json;

    my $existing = $self->db->select_one('SELECT * FROM samples WHERE id = ?', $id);
    return $self->render(json => { error => 'Sample not found' }, status => 404)
        unless $existing;

    try {
        $self->db->execute(
            'UPDATE samples SET client_name = ?, sample_type = ?, status = ?, notes = ?, updated_at = NOW()
             WHERE id = ?',
            $data->{client_name}  // $existing->{client_name},
            $data->{sample_type}  // $existing->{sample_type},
            $data->{status}       // $existing->{status},
            $data->{notes}        // $existing->{notes},
            $id
        );

        $self->_audit_log('update', 'sample', $id, {
            changes => $data,
            previous_status => $existing->{status},
        });

        my $updated = $self->db->select_one('SELECT * FROM samples WHERE id = ?', $id);
        $self->render(json => { data => $updated });
    } catch {
        $self->render(json => { error => "Failed to update sample: $_" }, status => 500);
    };
}

# DELETE /api/samples/:id
sub delete ($self) {
    my $id = $self->param('id');

    my $existing = $self->db->select_one('SELECT * FROM samples WHERE id = ?', $id);
    return $self->render(json => { error => 'Sample not found' }, status => 404)
        unless $existing;

    # Soft-delete would be better in a real LIMS, but this works for learning
    try {
        $self->db->execute('DELETE FROM samples WHERE id = ?', $id);
        $self->_audit_log('delete', 'sample', $id, { sample_code => $existing->{sample_code} });
        $self->render(json => { message => 'Sample deleted' });
    } catch {
        $self->render(json => { error => "Failed to delete sample: $_" }, status => 500);
    };
}

# POST /api/samples/import (CSV upload)
sub import_csv ($self) {
    my $upload = $self->req->upload('file');
    return $self->render(json => { error => 'No file uploaded' }, status => 400)
        unless $upload;

    require Text::CSV;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    my @rows;
    my $content = $upload->slurp;
    open my $fh, '<:encoding(UTF-8)', \$content or die "Cannot open: $!";

    my $header = $csv->getline($fh);
    $csv->column_names(@$header);

    while (my $row = $csv->getline_hr($fh)) {
        push @rows, $row;
    }
    close $fh;

    my $imported = 0;
    my @errors;

    $self->db->transaction(sub ($db) {
        for my $row (@rows) {
            try {
                my $year = (localtime)[5] + 1900;
                my $seq = $db->select_one(
                    "SELECT COUNT(*) + 1 as next_seq FROM samples WHERE EXTRACT(YEAR FROM created_at) = ?",
                    $year
                );
                my $code = sprintf("LAB-%d-%04d", $year, $seq->{next_seq});

                $db->insert(
                    'INSERT INTO samples (sample_code, client_name, sample_type, notes, received_by)
                     VALUES (?, ?, ?, ?, ?) RETURNING id',
                    $code,
                    $row->{client_name}  || 'Unknown',
                    $row->{sample_type}  || 'general',
                    $row->{notes}        || '',
                    $self->session('user_id')
                );
                $imported++;
            } catch {
                push @errors, "Row error: $_";
            };
        }
    });

    $self->render(json => {
        imported => $imported,
        errors   => \@errors,
        total    => scalar @rows,
    });
}

# Helper: write to audit log
sub _audit_log ($self, $action, $entity_type, $entity_id, $details = {}) {
    try {
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
        $self->app->log->warn("Audit log failed: $_");
    };
}

1;

package LabTrack::Controller::Test;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

# GET /api/tests
# Query params: ?category=chemistry&search=nicotine
sub list ($self) {
    my $category = $self->param('category');
    my $search   = $self->param('search');

    my @conditions;
    my @params;

    if ($category) {
        push @conditions, 'category = ?';
        push @params, $category;
    }
    if ($search) {
        push @conditions, '(name ILIKE ? OR method ILIKE ?)';
        push @params, "%$search%", "%$search%";
    }

    my $where = @conditions ? 'WHERE ' . join(' AND ', @conditions) : '';

    my $tests = $self->db->select_all(
        "SELECT * FROM test_definitions $where ORDER BY category, name", @params
    );

    $self->render(json => { data => $tests, total => scalar @$tests });
}

# GET /api/tests/:id
sub show ($self) {
    my $id = $self->param('id');

    my $test = $self->db->select_one(
        'SELECT * FROM test_definitions WHERE id = ?', $id
    );

    return $self->render(json => { error => 'Test not found' }, status => 404)
        unless $test;

    $self->render(json => { data => $test });
}

# POST /api/tests
sub create ($self) {
    my $data = $self->req->json;

    unless ($data->{name}) {
        return $self->render(
            json   => { error => 'Missing required field: name' },
            status => 400
        );
    }

    try {
        my $id = $self->db->insert(
            'INSERT INTO test_definitions (name, category, unit, min_range, max_range, method)
             VALUES (?, ?, ?, ?, ?, ?) RETURNING id',
            $data->{name},
            $data->{category}  // '',
            $data->{unit}      // '',
            $data->{min_range} // 0,
            $data->{max_range} // 0,
            $data->{method}    // ''
        );

        my $test = $self->db->select_one('SELECT * FROM test_definitions WHERE id = ?', $id);
        $self->render(json => { data => $test }, status => 201);
    } catch {
        $self->render(json => { error => "Failed to create test: $_" }, status => 500);
    };
}

# PUT /api/tests/:id
sub update ($self) {
    my $id   = $self->param('id');
    my $data = $self->req->json;

    my $existing = $self->db->select_one('SELECT * FROM test_definitions WHERE id = ?', $id);
    return $self->render(json => { error => 'Test not found' }, status => 404)
        unless $existing;

    try {
        $self->db->execute(
            'UPDATE test_definitions SET name = ?, category = ?, unit = ?, min_range = ?, max_range = ?, method = ?
             WHERE id = ?',
            $data->{name}      // $existing->{name},
            $data->{category}  // $existing->{category},
            $data->{unit}      // $existing->{unit},
            $data->{min_range} // $existing->{min_range},
            $data->{max_range} // $existing->{max_range},
            $data->{method}    // $existing->{method},
            $id
        );

        my $updated = $self->db->select_one('SELECT * FROM test_definitions WHERE id = ?', $id);
        $self->render(json => { data => $updated });
    } catch {
        $self->render(json => { error => "Failed to update test: $_" }, status => 500);
    };
}

1;
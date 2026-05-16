package LabTrack::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Crypt::Bcrypt qw(bcrypt bcrypt_check);
use Try::Tiny;

# POST /api/auth/register
sub register ($self) {
    my $data = $self->req->json;

    for my $field (qw(username email password)) {
        return $self->render(json => { error => "Missing: $field" }, status => 400)
            unless $data->{$field};
    }

    # Validate email format
    unless ($data->{email} =~ /^[\w.+-]+@[\w.-]+\.\w{2,}$/) {
        return $self->render(json => { error => 'Invalid email format' }, status => 400);
    }

    # Check for duplicates
    my $exists = $self->db->select_one(
        'SELECT id FROM users WHERE username = ? OR email = ?',
        $data->{username}, $data->{email}
    );
    if ($exists) {
        return $self->render(json => { error => 'Username or email already exists' }, status => 409);
    }

    try {
        # Hash password with bcrypt (cost factor 12)
        my $hashed = bcrypt($data->{password}, '2b', 12, undef);

        my $id = $self->db->insert(
            'INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?) RETURNING id',
            $data->{username}, $data->{email}, $hashed, $data->{role} // 'technician'
        );

        $self->session(user_id => $id, role => $data->{role} // 'technician');

        my $user = $self->db->select_one(
            'SELECT id, username, email, role, created_at FROM users WHERE id = ?', $id
        );
        $self->render(json => { data => $user }, status => 201);
    } catch {
        $self->render(json => { error => "Registration failed: $_" }, status => 500);
    };
}

# POST /api/auth/login
sub login ($self) {
    my $data = $self->req->json;

    return $self->render(json => { error => 'Username and password required' }, status => 400)
        unless $data->{username} && $data->{password};

    my $user = $self->db->select_one(
        'SELECT * FROM users WHERE username = ?', $data->{username}
    );

    unless ($user && bcrypt_check($data->{password}, $user->{password})) {
        return $self->render(json => { error => 'Invalid credentials' }, status => 401);
    }

    # Set session
    $self->session(user_id => $user->{id}, role => $user->{role});

    # Don't return password hash
    delete $user->{password};
    $self->render(json => { data => $user });
}

# POST /api/auth/logout
sub logout ($self) {
    $self->session(expires => 1);
    $self->render(json => { message => 'Logged out' });
}

# Middleware: optional auth (sets user info if logged in)
sub check_optional ($self) {
    if (my $user_id = $self->session('user_id')) {
        $self->stash(current_user_id => $user_id);
        $self->stash(current_role     => $self->session('role'));
    }
    return 1;
}

# Middleware: required auth (rejects if not logged in)
sub check_required ($self) {
    unless ($self->session('user_id')) {
        $self->render(json => { error => 'Authentication required' }, status => 401);
        return 0;
    }
    $self->stash(current_user_id => $self->session('user_id'));
    $self->stash(current_role     => $self->session('role'));
    return 1;
}

1;

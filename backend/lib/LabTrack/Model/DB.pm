package LabTrack::Model::DB;
use Mojo::Base -base, -signatures;

use DBI;
use Try::Tiny;

has 'dsn';
has 'username';
has 'password';
has '_dbh';

# Get or create database connection
sub dbh ($self) {
    if (!$self->_dbh || !$self->_dbh->ping) {
        my $dbh = DBI->connect(
            $self->dsn,
            $self->username,
            $self->password,
            {
                RaiseError     => 1,
                AutoCommit     => 1,
                PrintError     => 0,
                pg_enable_utf8 => 1,
            }
        ) or die "Database connection failed: $DBI::errstr";
        $self->_dbh($dbh);
    }
    return $self->_dbh;
}

# Execute a SELECT query and return all rows as array of hashrefs
sub select_all ($self, $sql, @params) {
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@params);
    return $sth->fetchall_arrayref({});
}

# Execute a SELECT and return first row as hashref
sub select_one ($self, $sql, @params) {
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@params);
    return $sth->fetchrow_hashref();
}

# Execute INSERT and return the new ID (PostgreSQL RETURNING)
sub insert ($self, $sql, @params) {
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@params);
    my $row = $sth->fetchrow_hashref();
    return $row->{id} if $row;
    return undef;
}

# Execute UPDATE/DELETE and return rows affected
sub execute ($self, $sql, @params) {
    my $sth = $self->dbh->prepare($sql);
    return $sth->execute(@params);
}

# Transaction wrapper
sub transaction ($self, $callback) {
    my $dbh = $self->dbh;
    try {
        $dbh->{AutoCommit} = 0;
        my $result = $callback->($self);
        $dbh->commit;
        $dbh->{AutoCommit} = 1;
        return $result;
    } catch {
        $dbh->rollback;
        $dbh->{AutoCommit} = 1;
        die "Transaction failed: $_";
    };
}

1;

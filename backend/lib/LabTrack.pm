package LabTrack;
use Mojo::Base 'Mojolicious', -signatures;

use LabTrack::Model::DB;

sub startup ($self) {
    # Load configuration
    my $config = $self->plugin('Config', { file => 'labtrack.conf' });

    # Set up secrets for signed cookies/sessions
    $self->secrets($config->{secrets} || ['labtrack-dev-secret-change-me']);

    # Session expiration (8 hours)
    $self->sessions->default_expiration(28800);

    # Initialize database connection helper
$self->helper(db => sub {
        state $db = do {
            my ($dsn, $user, $pass);

            if (my $url = $ENV{DATABASE_URL}) {
                # Parse Railway's DATABASE_URL format:
                # postgresql://user:pass@host:port/dbname
                if ($url =~ m{postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)}) {
                    $user = $1;
                    $pass = $2;
                    $dsn  = "dbi:Pg:dbname=$5;host=$3;port=$4";
                }
            }

            $dsn  //= $config->{database}{dsn}      // 'dbi:Pg:dbname=labtrack';
            $user //= $config->{database}{username}  // 'postgres';
            $pass //= $config->{database}{password}  // '';

            LabTrack::Model::DB->new(
                dsn      => $dsn,
                username => $user,
                password => $pass,
            );
        };
        return $db;
    });

    # CORS for React dev server
    $self->hook(before_dispatch => sub ($c) {
        $c->res->headers->header('Access-Control-Allow-Origin'  => 'http://localhost:5174');
        $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
        $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
        $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');

        # Handle preflight OPTIONS requests
        if ($c->req->method eq 'OPTIONS') {
            $c->render(text => '', status => 200);
            return;
        }
    });

    # Router
    my $r = $self->routes;

    # API namespace
    $r->get('/health' => sub ($c) { $c->render(json => { status => 'ok' }) });
    my $api = $r->under('/api')->to('Auth#check_optional');

    # Public routes
    $api->post('/auth/login')->to('Auth#login');
    $api->post('/auth/register')->to('Auth#register');
    $api->post('/auth/logout')->to('Auth#logout');

    # Protected routes (require authentication)
    my $auth = $api->under('/')->to('Auth#check_required');

    # Samples
    $auth->get('/samples')->to('Sample#list');
    $auth->get('/samples/:id')->to('Sample#show');
    $auth->post('/samples')->to('Sample#create');
    $auth->put('/samples/:id')->to('Sample#update');
    $auth->delete('/samples/:id')->to('Sample#delete');
    $auth->post('/samples/import')->to('Sample#import_csv');
    $auth->get('/samples/:id/export')->to('Sample#export_csv');

    # Test Definitions
    $auth->get('/tests')->to('Test#list');
    $auth->get('/tests/:id')->to('Test#show');
    $auth->post('/tests')->to('Test#create');
    $auth->put('/tests/:id')->to('Test#update');

    # Sample Tests (assign tests to samples, enter results)
    $auth->get('/samples/:sample_id/tests')->to('Result#list');
    $auth->post('/samples/:sample_id/tests')->to('Result#assign');
    $auth->put('/sample-tests/:id')->to('Result#update');
    $auth->post('/sample-tests/:id/approve')->to('Result#approve');

    # Dashboard
    $auth->get('/dashboard/stats')->to('Dashboard#stats');
    $auth->get('/dashboard/recent')->to('Dashboard#recent_activity');
    $auth->get('/dashboard/recent')->to('Dashboard#recent_activity');
    # Serve React frontend for any non-API route
    $r->any('/*whatever' => { whatever => '' } => sub ($c) {
        $c->reply->file($c->app->home->child('public', 'index.html'));
    });
}

1;

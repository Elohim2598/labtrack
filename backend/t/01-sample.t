use Test::More;
use Test::Mojo;

# Load the app
use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;

my $t = Test::Mojo->new('LabTrack');

# Test: API root should respond
$t->get_ok('/api/auth/login')
  ->status_is(400);  # No credentials = 400

# Test: Registration
$t->post_ok('/api/auth/register' => json => {
    username => 'testuser_' . int(rand(9999)),
    email    => 'test' . int(rand(9999)) . '@test.local',
    password => 'testpass123',
})
  ->status_is(201)
  ->json_has('/data/id')
  ->json_has('/data/username');

# Test: Get samples (requires auth from session set above)
$t->get_ok('/api/samples')
  ->status_is(200)
  ->json_has('/data')
  ->json_has('/total');

# Test: Create a sample
$t->post_ok('/api/samples' => json => {
    client_name => 'Test Client Corp',
    sample_type => 'water',
    notes       => 'Automated test sample',
})
  ->status_is(201)
  ->json_has('/data/sample_code')
  ->json_like('/data/sample_code' => qr/^LAB-\d{4}-\d{4}$/);

# Test: Missing required field
$t->post_ok('/api/samples' => json => {
    notes => 'No client name!',
})
  ->status_is(400)
  ->json_has('/error');

done_testing();

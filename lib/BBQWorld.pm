package BBQWorld;
use Mojo::Base 'Mojolicious';

use Mojo::Log;
use FindBin;

use BBQWorld::Model::Gather;
#use BBQWorld::Model::Tester;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by "my_app.conf"
    $self->{config} = $self->plugin('Config');

    $self->{log} =
      Mojo::Log->new( path => "$FindBin::Bin/../log/bbqworld.log" );

    $self->{log}->info("app mode: " . $self->app->mode);

    #  state $gather = BBQWorld::Model::Gather->new;
    $self->{gather} =
      BBQWorld::Model::Gather->new( $self->{config}, $self->{log} );

    $self->helper(
        gather => sub {
            my $c = shift;
            return $self->{gather};
        }
    );

    $self->helper(
        log => sub {
            my $c = shift;
            return $self->{log};
        }
    );

    $self->helper(
        config => sub {
            my $c = shift;
            return $self->{config};
        }
    );

    # Documentation browser under "/perldoc"
    #$self->plugin('PODRenderer') if $config->{perldoc};

    # Router
    my $r = $self->routes;

    # Normal route to controller
    #$r->get('/')->to('example#welcome');
    $r->get('/')->to('main#intro');

    $r->websocket('/status')->to('main#status');
}

1;

package BBQWorld;
use Mojo::Base 'Mojolicious';

use BBQWorld::Model::Gather;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by "my_app.conf"
    $self->{config} = $self->plugin('Config');

    #  state $gather = BBQWorld::Model::Gather->new;
    $self->{gather} = BBQWorld::Model::Gather->new( $self->{config} );

    # Documentation browser under "/perldoc"
    #$self->plugin('PODRenderer') if $config->{perldoc};

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('example#welcome');
}

1;

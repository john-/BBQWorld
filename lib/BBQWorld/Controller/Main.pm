package BBQWorld::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub intro {
  my $self = shift;

  # Render template "main/intro.html.ep" with message
  my $setpoint = $self->config->{pid}{setpoint};
  $self->render(msg => "Welcome to the bbq!  The set point is $setpoint°F");
}

sub status {
    my $c = shift;
    #print Dumper($c->gather);
    $c->log->info('Starting Websocket');
    
#    $c->send({json => $c->gather->stats});
    my $id = Mojo::IOLoop->recurring($c->config->{pid}{sampletime} => sub {
	my $loop = shift;
        $c->send({json => $c->gather->stats});
				     });

    $c->on(finish => sub {
        my ($c, $code, $reason) = @_;
	$c->log->info('Websocket closed');
	Mojo::IOLoop->remove($id)
	#$c->finish;
	   });

#    $c->on(json => sub {
#	my ($c, $hash) = @_;
#	
#	$hash->{msg} = "echo: $hash->{msg}";
#	$c->send({json => $hash});
#    });

    
}


1;

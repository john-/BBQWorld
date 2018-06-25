package BBQWorld::Model::Gather;

use strict;
use warnings;

use BBQWorld::Model::PID;
use BBQWorld::Model::Temps;
use BBQWorld::Model::AirIntake;
#use BBQWorld::Model::LCD;
#use BBQWorld::Model::Fan;
#use BBQWorld::Model::Valve;

use Data::Dumper;

use Mojo::IOLoop;

sub new {
    my ( $class, $config ) = @_;

    my $self = bless {}, $class;

    $self->{temps} = BBQWorld::Model::Temps->new( $config->{probes} );

    Mojo::IOLoop->recurring(
        1 => sub {
            $self->{temps}->cache_temps();
        }
    );

    $self->{pid} = BBQWorld::Model::PID->new( $config->{pid} );
    $self->{air_intake} = BBQWorld::Model::AirIntake->new;
    #$self->{fan} = BBQWorld::Model::Fan->new;
    #$self->{valve} = BBQWorld::Model::Valve->new;

    Mojo::IOLoop->recurring(
        4 => sub {
            my $res = $self->{pid}->calc_pid( $self->{temps}->get_ambient );
            $self->{air_intake}->set_volume( $res->{CO} );
            #$self->{fan}->set_speed( $res->{CO} );
            #$self->{valve}->set_state( $res->{CO} );
        }
    );

 #   $self->{LCD} = BBQWorld::Model::LCD->new();

 #   Mojo::IOLoop->recurring(
 #       1 => sub {
 #           $self->{LCD}->update_lcd( $self->{temps}->get_temps,
 #               $self->{pid}->get_values );
 #       }
 #   );

    return $self;
}

1;

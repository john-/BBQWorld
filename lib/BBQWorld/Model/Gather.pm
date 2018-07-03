package BBQWorld::Model::Gather;

use strict;
use warnings;

#use Mojo::Log;
#use FindBin;

use BBQWorld::Model::PID;
use BBQWorld::Model::Temps;

#use BBQWorld::Model::AirIntake;
use BBQWorld::Model::AirDevice;

use Data::Dumper;

use Mojo::IOLoop;

sub new {
    my ( $class, $config, $log ) = @_;

    my $self = bless {}, $class;

    $self->{temps} = BBQWorld::Model::Temps->new( $config->{probes} );

    $self->{log} = $log;

    #$self->{log} = Mojo::Log->new(path => "$FindBin::Bin/../log/bbqworld.log");

    #    Mojo::IOLoop->recurring(
    #        1 => sub {
    #            $self->{temps}->cache_temps();
    #        }
    #    );

    $self->{pid} = BBQWorld::Model::PID->new( $config->{pid} );

    my $temps = $self->{temps}->get_temps;   # prime the pump

    $self->{pid}->set_mode(1, $temps->{ambient}, 0); # turn the PID on
    
    $self->{fan} = BBQWorld::Model::AirDevice->new( $config->{air_devices}{fan},
        $self->{log} );
    $self->{valve} =
      BBQWorld::Model::AirDevice->new( $config->{air_devices}{valve},
        $self->{log} );

    #print Dumper($config->{air_devices}{fan});
    #    $self->{air_intake} = BBQWorld::Model::AirIntake->new;

    Mojo::IOLoop->recurring(
        $config->{pid}{sampletime} => sub {
            my $res;
            $res->{temps} = $self->{temps}->get_temps;
            my $out = $self->{pid}->calc_pid( $res->{temps} );
	    if ($out) {
		$res->{pid} = $out;
	    } else {
		return;   # probably in manual mode
	    }
	    
            $res->{intake}{fan} = $self->{fan}->set_speed( $res->{pid}{Output} );
            $res->{intake}{valve} =
              $self->{valve}->set_speed( $res->{pid}{Output} );
            $self->{stats} = $res;

#	    $self->{log}->info( Dumper($res) );
#            $res->{intakes} = $self->{air_intake}->set_volume( $res->{values}{CO} );
        }
    );

    return $self;
}

sub stats {
    my $self = shift;

    return $self->{stats};
}

1;

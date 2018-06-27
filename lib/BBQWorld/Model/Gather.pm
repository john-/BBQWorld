package BBQWorld::Model::Gather;

use strict;
use warnings;

use Mojo::Log;
use FindBin;

use BBQWorld::Model::PID;
use BBQWorld::Model::Temps;
#use BBQWorld::Model::AirIntake;
use BBQWorld::Model::AirDevice;

use Data::Dumper;

use Mojo::IOLoop;

sub new {
    my ( $class, $config ) = @_;

    my $self = bless {}, $class;

    $self->{temps} = BBQWorld::Model::Temps->new( $config->{probes} );

    $self->{log} = Mojo::Log->new(path => "$FindBin::Bin/../log/bbqworld.log");

#    Mojo::IOLoop->recurring(
#        1 => sub {
#            $self->{temps}->cache_temps();
#        }
#    );

    $self->{pid} = BBQWorld::Model::PID->new( $config->{pid} );
    $self->{fan} = BBQWorld::Model::AirDevice->new( $config->{air_devices}{fan}, $self->{log} );
    $self->{valve} = BBQWorld::Model::AirDevice->new( $config->{air_devices}{valve}, $self->{log} );
    #print Dumper($config->{air_devices}{fan});
#    $self->{air_intake} = BBQWorld::Model::AirIntake->new;

    Mojo::IOLoop->recurring(
        $config->{pid}{sampletime} => sub {
	    my $res;
	    $res->{temps}   = $self->{temps}->get_temps;
            $res->{pid}     = $self->{pid}->calc_pid( $res->{temps} );
            $res->{intake}{fan}     = $self->{fan}->set_speed( $res->{pid}{CO} );
            $res->{intake}{valve}   = $self->{valve}->set_speed( $res->{pid}{CO} );
	    $self->{log}->info( Dumper($res) );
#            $res->{intakes} = $self->{air_intake}->set_volume( $res->{values}{CO} );
        }
    );

    return $self;
}

1;

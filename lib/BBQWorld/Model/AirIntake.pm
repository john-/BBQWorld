package BBQWorld::Model::AirIntake;

use strict;
use warnings;

use BBQWorld::Model::Fan;
use BBQWorld::Model::Valve;

use Data::Dumper;

use Mojo::IOLoop;

sub new {
    my ( $class, $config ) = @_;

    my $self = bless {}, $class;

    $self->{fan} = BBQWorld::Model::Fan->new;
    $self->{valve} = BBQWorld::Model::Valve->new;

    return $self;
}

sub set_volume {
    my ($self, $CO) = @_;

    # Assume CO from -200 to 200 (based on recent gain settings...may change)
    my $max_co = 200;

    # turn CO into percent
    my $air_intake = int ($CO / $max_co * 100 + 0.5);

#    if ($air_intake lt 1) {
#	$self->{fan}->off;
#	$self->{valve}->close;
#	return;
#    }
    
    # valve is to 10%.   Fan is from 10-100%
    $self->{valve}->set_state($air_intake, 10);
    $self->{fan}->set_speed($air_intake, 10);

}

1;

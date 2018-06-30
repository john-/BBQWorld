package BBQWorld::Model::AirDevice;

use Data::Dumper;
use Carp;

sub new {
    my ( $class, $props, $log ) = @_;

    my $self = {
        log   => $log,
        props => $props,
    };

    bless $self, $class;

    $self->init_pwm;

    return $self;
}

sub _set_pwm {
    my ( $self, $prop, $value ) = @_;

    my @args = (
        sprintf(
            '/bin/echo %d > /sys/devices/platform/pwm-ctrl/%s',
            $value, $prop
        )
    );
    system(@args) == 0
      or $self->{log}->error("system @args failed: $?");

}

sub init_pwm {
    my $self = shift;

    my $id = $self->{props}{pwm};

    $self->_set_pwm( "freq$id", $self->{props}{freq} );

    $self->_set_pwm( "enable$id", 1 );
}

sub set_speed {
    my ( $self, $co ) = @_;

    unless ( $co =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i ) {
        $self->{log}->error("not a number: $co");
        return;
    }

    # fan can be configured to operate at min level
    # valve

    my $duty_min = $self->{props}{duty_min};
    my $duty_max = $self->{props}{duty_max};

    # map to pwm range
    my $duty = $self->map_to_duty(
        $co,
        $self->{props}{co_min},
        $self->{props}{co_max},
        $duty_min, $duty_max
    );

    $duty = sprintf( '%.0f', $duty );

    if ( $duty > $duty_max ) { $duty = $duty_max }
    if ( $duty < $duty_min ) { $duty = $duty_min }

    # a device may kick in at certain levels only
    if ( $co < $self->{props}{co_min} ) {
	$self->{log}->info(
            sprintf('turning off the intake device.  co: %.2f  co_min: %.2f',
            $co, $self->{props}{co_min}));
        $duty = $self->{props}{duty_off};
    }

    $self->{log}->info("co: $co duty: $duty");

    $self->_set_pwm( "duty$self->{props}{pwm}", $duty );

    return { co => $co, duty => $duty };
}

sub map_to_duty {
    my ( $self, $x, $in_min, $in_max, $out_min, $out_max ) = @_;

    return ( $x - $in_min ) * ( $out_max - $out_min ) / ( $in_max - $in_min ) +
      $out_min;
}

1;

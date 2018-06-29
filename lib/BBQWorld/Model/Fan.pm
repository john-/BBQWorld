package BBQWorld::Model::Fan;

use Mojo::Log;
use FindBin;

use Data::Dumper;
use Carp;

use constant {
    MIN => 750,  # 750 is the slowest speed the fan will start at
    MAX => 1024,
};

sub new {
    my $class = shift;

    my $log = Mojo::Log->new(path => "$FindBin::Bin/../log/bbqworld.log");
    
    my $self = {
#        fan_dev => '/sys/devices/platform/pwm-ctrl',
	log => $log,
    };

    bless $self, $class;

    $self->init_pwm;

    return $self;
}

sub _set_pwm {
    my ($self, $prop, $value) = @_;

    my @args = ( sprintf( '/bin/echo %d > /sys/devices/platform/pwm-ctrl/%s', $value, $prop) );
    system(@args) == 0
      or $self->{log}->error("system @args failed: $?");
    
}

sub init_pwm {
    my $self = shift;

    $self->_set_pwm('freq1', 25000);

    $self->_set_pwm('enable1', 1);
}

sub set_speed {
    my ( $self, $speed, $threshold ) = @_;

    unless ( $speed =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i ) {
        $self->{log}->error("not a number: $speed");
        return;
    }

    if ($speed lt $threshold) { $speed = -100 }
    
    # map to pwm range
    my $duty = $self->map_to_duty( $speed, 0, 100, MIN, MAX );

    $duty = sprintf( '%.0f', $duty );

    if ( $duty > MAX ) { $duty = MAX }
    if ( $duty < MIN ) { $duty = 0   }

    $self->{log}->info("speed: $speed duty: $duty");

    $self->_set_pwm('duty1', $duty);
}

sub map_to_duty {
    my ( $self, $x, $in_min, $in_max, $out_min, $out_max ) = @_;

    return ( $x - $in_min ) * ( $out_max - $out_min ) / ( $in_max - $in_min ) +
      $out_min;
}

1;

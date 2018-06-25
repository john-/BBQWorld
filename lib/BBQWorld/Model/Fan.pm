package BBQWorld::Model::Fan;

use Data::Dumper;
use Carp;

use constant {
    MIN => 750,  # 750 is the slowest speed the fan will start at
    MAX => 1024,
};

sub new {
    my $class = shift;

    my $self = {

    };

    bless $self, $class;

    $self->init_pwm;

    return $self;
}

sub init_pwm {

    #my $self = shift;

    my @args = ('/bin/echo 25000 > /sys/devices/platform/pwm-ctrl/freq1');
    system(@args) == 0
      or die "system @args failed: $?";

    my @args = ('/bin/echo 1 > /sys/devices/platform/pwm-ctrl/enable1');
    system(@args) == 0
      or die "system @args failed: $?";

}

sub set_speed {
    my ( $self, $speed, $threshold ) = @_;

    unless ( $speed =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i ) {
        print "not a number: $speed\n";
        return;
    }

    if ($speed lt $threshold) { $speed = -100 }
    
    # map to pwm range
    my $duty = $self->map_to_duty( $speed, 0, 100, MIN, MAX );

    $duty = sprintf( '%.0f', $duty );

    if ( $duty > MAX ) { $duty = MAX }
    if ( $duty < MIN ) { $duty = 0   }

    print "speed: $speed duty: $duty\n";

    my @args = ("/bin/echo $duty > /sys/devices/platform/pwm-ctrl/duty1");
    system(@args) == 0
        or die "system @args failed: $?";

}

sub map_to_duty {
    my ( $self, $x, $in_min, $in_max, $out_min, $out_max ) = @_;

    return ( $x - $in_min ) * ( $out_max - $out_min ) / ( $in_max - $in_min ) +
      $out_min;
}

1;

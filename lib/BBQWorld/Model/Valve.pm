package BBQWorld::Model::Valve;

use Data::Dumper;
use Carp;

use constant {
    MIN => 55,   # 52 is servo limit.   55 is valve fully closed.
    MAX => 102,
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

    my @args = ('/bin/echo 50 > /sys/devices/platform/pwm-ctrl/freq0');
    system(@args) == 0
      or die "system @args failed: $?";

    my @args = ('/bin/echo 1 > /sys/devices/platform/pwm-ctrl/enable0');
    system(@args) == 0
      or die "system @args failed: $?";

}

sub set_state {
    my ( $self, $state, $threshold ) = @_;

    unless ( $state =~ /^[+-]?(?=\.?\d)\d*\.?\d*(?:e[+-]?\d+)?\z/i ) {
        print "not a number: $state\n";
        return;
    }

    # map to pwm range
    my $duty = $self->map_to_duty( $state, 0, $threshold, MIN, MAX );

    # limit to

    $duty = sprintf( '%.0f', $duty );

    # when I want to utlize fan as variable control use this
    if ( $duty > MAX ) { $duty = MAX }
    if ( $duty < MIN ) { $duty = MIN   }

    # for initial working with setup make it open or closed
#    if ( $duty >= MIN ) { $duty = MAX }
#    if ( $duty < MIN ) { $duty = MIN   }

    print "state: $state duty: $duty\n";

    my @args = ("/bin/echo $duty > /sys/devices/platform/pwm-ctrl/duty0");
    system(@args) == 0
        or die "system @args failed: $?";

}

sub map_to_duty {
    my ( $self, $x, $in_min, $in_max, $out_min, $out_max ) = @_;

    return ( $x - $in_min ) * ( $out_max - $out_min ) / ( $in_max - $in_min ) +
      $out_min;
}

1;

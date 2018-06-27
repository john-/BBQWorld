package BBQWorld::Model::PID;

use Data::Dumper;
use Carp;

sub new {
    my ( $class, $args ) = @_;

    croak "must specify all params"
      unless defined $args->{Kp}
      and defined $args->{Ki}
      and defined $args->{Kd}
      and defined $args->{setpoint}
      and defined $args->{sampletime};

    my $self = {
        gains => {
            Kp => $args->{Kp},
            Ki => $args->{Ki} * $args->{sampletime},
            Kd => $args->{Kd} / $args->{sampletime},
        },
        setpoint    => $args->{setpoint},
        sampletime  => $args->{sampletime},
        prev_time   => time(),
        prev_error  => 0,
        total_error => 0,
    };

    bless $self, $class;

    return $self;
}

sub calc_pid {
    my ( $self, $temps ) = @_;

    my $PV = $temps->{ambient};
    
    my $now        = time();
    my $time_delta = $now - $self->{prev_time};
    if ( $time_delta < $self->{sampletime} ) {
        return;
    }

    my $error = $self->{setpoint} - $PV;

    $self->{total_error} += $error;
    my $deriv_of_error = $error - $self->{prev_error};

    my $P = $error * $self->{gains}{Kp};
    my $I = $self->{total_error} * $self->{gains}{Ki};
    my $D = $deriv_of_error * $self->{gains}{Kd};

    my $total = $P + $I + $D;

    #print sprintf( "PV:%.0f P:%.0f I:%.0f D:%.0f CO:%.0f\n",
    #    $PV, $P, $I, $D, $total );

    $self->{prev_error} = $error;
    $self->{prev_time}  = $now;

    my %res = (
        PV => $PV,
        P  => $P,
        I  => $I,
        D  => $D,
        CO => $total,
        SP => $self->{setpoint}
    );

    $self->{values} = \%res;

    return $self->{values};
}

sub get_values {
    my $self = shift;

    return $self->{values};
}

sub get_gains {
    my $self = shift;

    return $self->{gains};
}

1;

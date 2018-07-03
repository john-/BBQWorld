package BBQWorld::Model::PID;

use Data::Dumper;
use Carp;

#use contant {
#    AUTOMATIC = 1,
#    MANUAL = 0,
#}

sub new {
    my ( $class, $args ) = @_;

    croak "must specify all params"
      unless defined $args->{Kp}
      and defined $args->{Ki}
      and defined $args->{Kd}
      and defined $args->{setpoint}
      and defined $args->{sampletime};

    my $self = {
        setpoint  => $args->{setpoint},
	in_auto => 0,  # start out in manual mode
	sampletime => $args->{sampletime},
        last_time   => time(),

#        gains => {
#            Kp => $args->{Kp},
#            Ki => $args->{Ki} * $args->{sampletime},
#            Kd => $args->{Kd} / $args->{sampletime},
#        },
        #sampletime  => $args->{sampletime},
#        prev_error  => 0,   # these two will come from new initialize sub?
#        total_error => 0,
    };

    bless $self, $class;

    $self->set_output_limits(0, 1023);  # set to Odroid C2 PWM limits
    $self->set_tunings($args->{Kp}, $args->{Ki}, $args->{Kd}, $args->{POn});

    return $self;
}

sub set_output_limits {
    my ($self, $min, $max) = @_;

    if ($min >= $max) { return; }

    $self->{out_min} = $min;
    $self->{out_max} = $max;

    if ($self->{in_auto}) {
	if ($self->{output} > $self->{out_max}) { $self->{output} = $self->{out_max}
	} elsif ($self->{output} < $self->{out_min}) { $self->{output} = $self->{out_min} }

	if ($self->{output_sum} > $self->{out_max}) { $self->{output_sum} = $self->{out_max}
	} elsif ($self->{output_sum} < $self->{out_min}) { $self->{output_sum} = $self->{out_min} }
    }
}

sub set_tunings {
    my ($self, $Kp, $Ki, $Kd, $POn) = @_;

    if ( ($Kp < 0) || ($Ki < 0) || ($Kd < 0) ) { return; }

    $self->{POn} = $POn;

    $self->{gains}{disp_Kp} = $Kp;
    $self->{gains}{disp_Ki} = $Ki;
    $self->{gains}{disp_Kd} = $Kd;

    $self->{gains}{Kp} = $Kp;
    $self->{gains}{Ki} = $Ki * $self->{sampletime};
    $self->{gains}{Kd} = $Kd / $self->{sampletime};
}

sub set_mode {
    my ($self, $mode, $input, $output) = @_;

    my $new_auto = 0;
    if ($mode == 1) { $new_auto = 1 }

    if ($new_auto && !$self->{in_auto}) {
	$self->initialize($input, $output);
    }

    $self->{in_auto} = $new_auto;
}

# does all the things that need to happen to ensure a bumpless transfer
# from manual to automatic mode.
sub initialize {
    my ($self, $input, $output) = @_;

    $self->{output_sum} = $output;
    $self->{last_input} = $input;

    if ($self->{output_sum} > $self->{out_max}) { $self->{output_sum} = $self->{out_max}
    } elsif ($self->{output_sum} < $self->{out_min}) { $self->{output_sum} = $self->{out_min} }					       
}

sub calc_pid {
    my ( $self, $temps ) = @_;

    if (!$self->{in_auto}) { return; }
    
    my $now        = time();
    my $time_delta = $now - $self->{last_time};
    if ( $time_delta < $self->{sampletime} ) {
        return;
    }

    my $input = $temps->{ambient};
    my $error = $self->{setpoint} - $input;
    my $dInput = $input - $self->{last_input};
    $self->{output_sum} += $self->{gains}{Ki} * $error;   # I

    # Add Proportional on Measurement, if P_ON_M is specified
    if ($self->{POn} eq 'p_on_m') {
        $self->{output_sum} -= $self->{gains}{kp} * dInput;
    }

    if ( $self->{output_sum} > $self->{out_max} ) { $self->{output_sum} = $self->{out_max};
    } elsif ( $self->{output_sum} < $self->{out_min} ) { $self->{output_sum} = $self->{out_min}; }

    # Add Proportional on Error, if P_ON_E is specified
    my $output;
    if ($self->{POn} eq 'p_on_e') {
        $output = $self->{gains}{Kp} * $error;
    } else {
        $output = 0;
    }

    # Compute Rest of PID Output
    my $D = $self->{gains}{kd} * $dInput;
    $output += $self->{output_sum} - $D;

    if ($output > $self->{out_max}) {
	$output = $self->{out_max};
    } elsif ($output < $self->{out_min}) {
	$output = $self->{out_min};
    }

    #$self->{output} = $output;

    #$self->{total_error} += $error;
    #my $deriv_of_error = $error - $self->{prev_error};

    #my $P = $error * $self->{gains}{Kp};
    #my $I = $self->{total_error} * $self->{gains}{Ki};
    #my $D = $deriv_of_error * $self->{gains}{Kd};

    #my $total = $P + $I + $D;

    #print sprintf( "input:%.0f P:%.0f I:%.0f D:%.0f CO:%.0f\n",
    #    $input, $P, $I, $D, $total );

#    $self->{prev_error} = $error;
    $self->{last_input} = $input;
    $self->{last_time}  = $now;

    my %res = (
        Input => $input,
        #P  => $P,
        OutputSum  => $self->{output_sum},
        D  => $D,
        Output => $output,
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

package BBQWorld::Model::Temps;

use Data::Dumper;
use Carp;

sub new {
    my ( $class, $probes ) = @_;

    croak "must specify ambient temperature probe"
      unless defined $probes->{ambient};

    my $self = { probes => $probes, };

    bless $self, $class;

    return $self;
}

sub get_temps {
    my $self = shift;

    my %temps;
    foreach my $sensor ( keys %{ $self->{probes} } ) {

        #print "sensor: $sensor\n";

        open( MYINPUTFILE, $self->{probes}{$sensor} );
        my (@lines) = <MYINPUTFILE>;    # read file into list

        my $temp;
        $temps{$sensor} = 'Not available';    # assume worst case
        foreach my $line (@lines) {

            #print "line $count:$_\n";
            if ( $line =~ /t=(\d+)/ ) {
                $temp = $1 / 1000 * 9 / 5 + 32;
                $temps{$sensor} = $temp;
            }
        }
        close(MYINPUTFILE);
    }

    return \%temps;
}

#sub get_ambient {
#    my $self = shift;

#    return $self->{temps}{ambient};
#}

#sub get_temps {
#    my $self = shift;

#    return $self->{temps};
#}

1;

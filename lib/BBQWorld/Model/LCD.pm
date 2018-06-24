package BBQWorld::Model::LCD;

use WiringPi::API;

use constant {
    OUTPUT => 1,
    INPUT  => 0,
    HIGH   => 1,
    LOW    => 0
};

use Data::Dumper;
use Carp;

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->init_lcd;

    return $self;
}

sub init_lcd {
    my $self = shift;

    my $gpio = WiringPi::API->new;

    $gpio->setup();

    my %args = (
        rows => 2,     # number of rows. eg: 2 or 4
        cols => 16,    # number of columns. eg: 16 or 20
        bits => 4,     # width of the interface (4 or 8)
        rs   => 7,     # pin number of the LCD's RS pin
        strb => 0,     # pin number of the LCD's strobe (E) pin
        d0   => 2,
        d1   => 3,
        d2   => 1,
        d3   => 4,     # pin number for LCD data pin 8
        d4   => 0,     # pin number for LCD data pin 8
        d5   => 0,     # pin number for LCD data pin 8
        d6   => 0,     # pin number for LCD data pin 8
        d7   => 0,     # pin number for LCD data pin 8
    );

    my $fd = $gpio->lcd_init(%args);

    $self->{fd}   = $fd;
    $self->{gpio} = $gpio;

    #$api->lcd_clear($fd);
    $self->turn_off_leds;

}

sub update_lcd {
    my ( $self, $temps, $pidstats ) = @_;

    #    my $temps = $self->{gather}->get_temps;
    #    my $pidstats = $self->{gather}->get_pidstats;

    my $ambient_temp =
      exists $temps->{ambient} ? sprintf( 'A:%.0f', $temps->{ambient} ) : '';
    my $set_point =
      exists $pidstats->{SP} ? sprintf( 'S:%.0f', $pidstats->{SP} ) : '';
    my $internal_temp =
      exists $temps->{internal} ? sprintf( 'I:%.0f', $temps->{internal} ) : '';

    my $txt = $ambient_temp . $set_point . $internal_temp;

    $self->{gpio}->lcd_position( $self->{fd}, 0, 0 );
    $self->{gpio}->lcd_puts( $self->{fd}, $txt );
    print "$txt\n";

    $txt = sprintf( 'D:%.0f', $pidstats->{CO} );

    $self->{gpio}->lcd_position( $self->{fd}, 0, 1 );
    $self->{gpio}->lcd_puts( $self->{fd}, $txt );

}

sub turn_off_leds {
    my $self = shift;

    my @lights = ( 21, 22, 23, 24, 11, 26, 27 );

    foreach my $light (@lights) {

        $self->{gpio}->pin_mode( $light, OUTPUT );
        $self->{gpio}->write_pin( $light, LOW );
    }
}

1;

package Mojo::TypeModel;

use Mojo::Base -base;

use Carp ();

sub copies { state $copies = [] }

sub model {
  my ($self, $type, @args) = @_;
  Carp::croak "type $type not understood"
    unless my $class = $self->types->{$type};

  my %args = (@args == 1 ? %{$args[0]} : @args);
  $args{$_} = $self->$_() for grep { !exists $args{$_} } @{ $self->copies };
  return $class->new(%args);
}

sub types { state $types = {} }

1;

=head1 NAME

Mojo::TypeModel - A very simple model system using Mojo::Base

=head1 DESCRIPTION

A model system using L<Mojo::Base> and primarily for L<Mojolicious> applications.
The models can call other models and can pass data to them (like db connections).

Additionally, L<Mojolicious::Plugin::TypeModel> is included to build helpers for models.

=head1 EXAMPLE

This is a (reduced) model from the L<CarPark> application.

The base model is simply:

  package CarPark::Model;

  use Mojo::Base 'Mojo::TypeModel';

  use CarPark::Model::Door;
  use CarPark::Model::GPIO;
  use CarPark::Model::User;

  has config => sub { Carp::croak 'config is required' };
  has db => sub { Carp::croak 'db is required' };

  sub copies { state $copies = [qw/config db/] }

  sub types {
    state $types = {
      door => 'CarPark::Model::Door',
      gpio => 'CarPark::Model::GPIO',
      user => 'CarPark::Model::User',
    };
  }

Then a model class inherits from it

  package CarPark::Model::User;

  use Mojo::Base 'CarPark::Model';

  sub exists {
    my $self = shift;
    my $db = $self->db;
    # use db to check
  }

A model instance's C<model> method is used to construct other models.

  package CarPark::Model::Door;

  use Mojo::Base 'CarPark::Model';

  sub is_open {
    my $self = shift;
    return !!$self->model('gpio')->pin_state(16);
  }

Helper methods may be installed via the plugin.

 package MyApp;

 use Mojo::Base 'Mojolicious';

 sub startup {
    my $app = shift;

    ...

    my $base = CarPark::Model->new(
      config => { ... },
      db => SomeDB->new(...),
    );

    $app->plugin(TypeModel => {base => $base});

    ...

    $app->routes->get('/door_state' => sub {
      my $c = shift;
      my $state = $c->model->door->is_open ? 'open' : 'closed';
      $c->render(text => "Door is $state");
    });
  }

The C<copies> properties propagate when instantiated via another model instance's C<model> method.

  my $exists = CarPark->new(config => {...}, db => $db)->model('user')->exists;

... which with the plugin is the same as

  my $exists = $app->model->user->exists;

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-TypeModel>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by L</AUTHOR> and L</CONTRIBUTORS>.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

package kadai::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use DBIx::Sunny;
use DBD::mysql;

sub dbh {
    my $self = shift;
    $self->{_dbh} ||= DBIx::Sunny->connect("dbi:mysql:database=kadai",'root','',{
        Callbacks => {
            connected => sub {
                my $conn = shift;
                $conn->do(<<EOF);

CREATE TABLE IF NOT EXISTS entry (
    id INTEGER NOT NULL PRIMARY KEY auto_increment,
    body TEXT
);
EOF
return;
            }
        }
        });
}

filter 'set_title' => sub {
    my $app = shift;
    sub {
        my ( $self, $c )  = @_;
        $c->stash->{site_name} = __PACKAGE__;
        $app->($self,$c);
    }
};

get '/' => [qw/set_title/] => sub {
    my ( $self, $c )  = @_;
    my $dbh = $self->dbh;
    my @data = $dbh->select_all(
        q{SELECT * FROM entry}
        );

    $c->render('index.tx', { greeting => "Hello", entries => @data });

};

post '/' => sub{
    my ($self, $c) = @_;
    my $text = $c->req->param('text');

    $self->dbh->query(
        q{INSERT INTO entry (id, body) VALUES (NULL,?)},
        $text
    );

    $c->redirect('/');
};

get '/json' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'q' => {
            default => 'Hello',
            rule => [
                [['CHOICE',qw/Hello Bye/],'Hello or Bye']
            ],
        }
    ]);
    $c->render_json({ greeting => $result->valid->get('q') });
};

1;


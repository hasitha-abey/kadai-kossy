package kadai::Web;

use strict;
use warnings;
use utf8;
use Kossy;
use DBIx::Sunny;
use DBD::mysql;
use Data::Dumper;

sub dbh { 
    my $self = shift;
    $self->{_dbh} ||= DBIx::Sunny->connect("dbi:mysql:database=kadai",'root','',{
        Callbacks => {
            connected => sub {
                my $conn = shift;
                $conn->do(<<EOF);
CREATE TABLE IF NOT EXISTS entry (
    id INTEGER NOT NULL PRIMARY KEY auto_increment,
    task TEXT,
    date TEXT
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
get '/' => sub {
    my ( $self, $c )  = @_;
    my $dbh = $self->dbh;
    my @data = $dbh->select_all(
        q{SELECT * FROM entry}
        );

    $c->render('index.tx', { entries => @data });

};

post '/add' => sub{
    my ($self, $c) = @_;
    my $task = $c->req->param('task');
    my $date = $c->req->param('date');

    $self->dbh->query(
        q{INSERT INTO entry (id, task, date) VALUES (NULL,?,?)},
        $task, $date
    );

    $c->redirect('/');
};

post '/erase/:id' => sub{
    my ($self, $c) = @_;
    my $erase_id = $c->args->{id};
    $self->dbh->query(
        q{DELETE FROM entry WHERE id=?},
        $erase_id
    );

    $c->redirect('/');
};

post '/changeform/:id' => sub {
    my ( $self, $c )  = @_;
    my $change_id = $c->args->{id};
     my $entry= $self->dbh->select_row(
        q{SELECT * FROM entry WHERE id=?;},
        $change_id
        );

    $c->render('change.tx', {entry => $entry});
};

post '/change/:id' => sub{
    my ($self, $c) = @_;
    my $change_id = $c->args->{id};
    my $task = $c->req->param('change');
    $self->dbh->query(
        q{UPDATE entry SET  task=? WHERE id=?},
        $task, $change_id

    );

    $c->redirect('/');
};

post '/search' => sub {
    my ( $self, $c )  = @_;
    my $search = $c->req->param('search');
    my $entry= $self->dbh->select_all(
        q{SELECT * FROM entry WHERE task=?;},
        $search
        );

    $c->render('search.tx', {entries => $entry});
};



1;


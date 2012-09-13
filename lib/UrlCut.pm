package UrlCut;
use Mojo::Base 'Mojolicious';
use DBI;

# This method will run once at server start
sub startup {
  my $self = shift;

  # データベース作成
  my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:");
  
  # テーブル作成
  my $create_table = q{ CREATE TABLE urls (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT) };
  $dbh->do($create_table);

  # Router
  my $r = $self->routes;

  # URLの入力画面
  $r->get('/' => sub {
    my $self = shift;
    $self->stash(from => $self->flash('from'));
    $self->stash(to   => $self->flash('to'));
    return $self->render('index');
  });

  # 短縮URLの登録
  $r->post('/create' => sub {
    my $self = shift;
    
    # 登録
    {
      my $url = $self->param('url');
      my $sth = $dbh->prepare(q{ INSERT INTO urls(url) VALUES (?) });
      $sth->execute($url) or die $dbh->errstr;
    }

    # 取得
    {
      my $sth = $dbh->prepare(q{ SELECT id, url FROM urls WHERE ROWID = LAST_INSERT_ROWID() });
      $sth->execute() or die $dbh->errstr;
      my ($id, $url) = $sth->fetchrow_array;
      $self->flash(from => $url);
      $self->flash(to   => sprintf("%s/%d", $self->req->url->base, $id));
    }
    
    return $self->redirect_to('/');
  });

  # 短縮URLで来たらリダイレクト
  $r->any('/:id' => sub {
    my $self = shift;
    my $sth = $dbh->prepare(q{ SELECT url FROM urls WHERE id = ? });
    $sth->execute($self->param('id')) or die $dbh->errstr;
    my ($url) = $sth->fetchrow_array;
    return $self->redirect_to($url);
  });
}

1;

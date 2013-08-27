use strict;
use warnings;

package MyApp;
use Wx qw(
    :frame
    :textctrl
    :sizer
    :panel
    :window
    :id
    :filedialog
    :colour
);
use Wx::Event qw(EVT_BUTTON);
use base 'Wx::App';
use Path::Tiny;
use Try::Tiny;
use Log::Any::Test;
use Log::Any qw($log);
use XML::ITS::WICS qw(xml2html);

sub OnInit {
    my( $self ) = @_;
    # create a new frame (a frame is a top level window)
    my $frame = Wx::Frame->new(
        undef,           # parent window
        -1,              # ID -1 means any
        'Convert ITS-Decorated Files',   # title
        [-1, -1],        # default position
        [350, 250],      # size
    );
    $self->{main_frame} = $frame;

    my $topsizer = Wx::BoxSizer->new(wxVERTICAL);
    # create Wx::Panel to use as a parent
    my $panel = Wx::Panel->new(
        $frame, -1, [-1,-1], [-1,-1],
        wxTAB_TRAVERSAL|wxBORDER_NONE
    );
    # create a text control with minimal size 100x60
    my $text = Wx::TextCtrl->new(
        $panel, -1, '',
        [-1,-1],[400,240],
        wxTE_MULTILINE|wxTE_READONLY|wxHSCROLL
    );
    $topsizer->Add(
        $text,
        1,           # make vertically stretchable
        wxEXPAND |   # make horizontally stretchable
        wxALL,       # and make border all around
        10           # set border width to 10
    );
    my $choose_file_btn     = Wx::Button->new($panel, wxID_ANY, 'Choose File...');
    EVT_BUTTON( $self, $choose_file_btn, sub {
            my ($self, $event) = @_;
            $self->{file_paths} = _open_files($frame);
            $text->SetValue(join "\n",@{ $self->{file_paths} } );
        }
    );
    my $convert_btn     = Wx::Button->new($panel, wxID_OK, 'Convert');
    EVT_BUTTON( $self, $convert_btn, sub {
            my ($self, $event) = @_;
            $self->_convert_files;
        }
    );
    my $close_btn = Wx::Button->new($panel, wxID_CANCEL, 'Close');
    EVT_BUTTON( $self, $close_btn, sub {
            my ($self, $event) = @_;
            $frame->Destroy;
        }
    );
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $buttonsizer->Add(
        $convert_btn,
        0,           # make horizontally unstretchable
        wxALL,       # make border all around (implicit top alignment)
        10           # set border width to 10
    );
    $buttonsizer->Add(
        $close_btn,
        0,           # make horizontally unstretchable
        wxALL,       # make border all around (implicit top alignment)
        10           # set border width to 10
    );
    $buttonsizer->Add(
        $choose_file_btn,
        0,           # make horizontally unstretchable
        wxALL,       # make border all around (implicit top alignment)
        10           # set border width to 10
    );
    $topsizer->Add(
        $buttonsizer,
        0,             # make vertically unstretchable
        wxALIGN_CENTER # no border and centre horizontally
    );
    $panel->SetSizer( $topsizer );
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    $mainsizer->Add($panel, 1, wxEXPAND|wxALL, 0);
    # use the sizer for layout and size frame
    # preventing it from being resized to a
    # smaller size;
    $frame->SetSizerAndFit($mainsizer);
    $frame->Show( 1 );
    return 1;
}

#returns an array pointer of paths to user-specified files to open
sub _open_files {
    my ($frame) = @_;

    my $fileDialog = Wx::FileDialog->new(
        $frame, 'Choose ITS-decorated XML file', '',
             '.', '*.*',
             wxFD_OPEN|wxFD_MULTIPLE|wxFD_FILE_MUST_EXIST);

    my $fileDialogStatus = $fileDialog->ShowModal();

    my @paths = $fileDialog->GetPaths();
    if ( $fileDialogStatus == wxID_OK ) {
        return \@paths;
    };
    return [];
}

sub _convert_files {
    my ($self) = @_;
    my $frame = Wx::Frame->new(
        $self->{main_frame},# parent window
        -1,                 # ID -1 means any
        'Conversion Logs',   # title
        [-1, -1],           # default position
        [100, 100],         # size (overridden by textCtrl size)
    );my $topsizer = Wx::BoxSizer->new(wxVERTICAL);
    # create Wx::Panel to use as a parent
    my $panel = Wx::Panel->new(
        $frame, -1, [-1,-1], [-1,-1],
        wxTAB_TRAVERSAL|wxBORDER_NONE
    );
    # create a text control with minimal size 100x60
    my $text = Wx::TextCtrl->new(
        $panel, -1, '',
        [-1,-1],[400,600],
        #multiline, read-only, scrollable, allow styles
        wxTE_MULTILINE|wxTE_READONLY|wxHSCROLL|wxTE_RICH2
    );
    $topsizer->Add(
        $text,
        1,           # make vertically stretchable
        wxEXPAND |   # make horizontally stretchable
        wxALL,       # and make border all around
        10           # set border width to 10
    );
    $panel->SetSizer( $topsizer );
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    $mainsizer->Add($panel, 1, wxEXPAND|wxALL, 0);
    # use the sizer for layout and size frame
    # preventing it from being resized to a
    # smaller size;
    $frame->SetSizerAndFit($mainsizer);
    $frame->Show( 1 );

    my $warning_style = Wx::TextAttr->new();
    $warning_style->SetTextColour(wxRED);
    my $normal_style = Wx::TextAttr->new();
    $normal_style->SetTextColour(wxBLACK);

    for my $path (@{ $self->{file_paths} }){
        $path = path($path);
        $log->clear;
        try{
            my $html = xml2html($path);
            my $new_path = _get_new_path($path);
            my $fh = path($new_path)->
                filehandle('>:utf8');
            print $fh ${ $html };
            $text->SetDefaultStyle($normal_style);
            $text->AppendText(
                join "\n", map {
                    $_->{message}
                } @{$log->msgs});
        }catch{
            $text->SetDefaultStyle($warning_style);
            $text->AppendText($_);
        };
    }
}

sub _get_new_path {
    my ($old_path) = @_;
    my $name = $old_path->basename;
    my $dir = $old_path->dirname;

    #new file will have html extension instead of whatever there was before
    $name =~ s/(\.[^.]+)?$/.html/;
    # if other file with same name exists, just iterate numbers to get a new,
    # unused file name
    if(path($dir, $name)->exists){
        my $counter = 1;
        $name =~ s/\.html$//;
        while(path($dir, $name . "-$counter.html")->exists){
            $counter++;
        }
        return path($dir, $name . "-$counter.html");
    }
    return path($dir, $name);
}

package main;
my $app = MyApp->new;
$app->MainLoop;

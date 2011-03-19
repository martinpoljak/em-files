EventMachine Files
==================

**em-files** solve problem of blocking disk IO when operating with 
large files. Use [EventMachine][4] for multiplexing reads and writes
to small blocks performed in standalone EM ticks. They speed down the
file IO operations of sure, but allow running other tasks with them 
simultaneously (from EM point of view).

API is similar to classic Ruby file IO represented by [File][1] class.
See an example:

    require "em-files"
    EM::run do
        EM::File::open("some_file.txt", "r") do |io|
            io.read(1024) do |data|     # writing works by very similar way, of sure
                puts data
                io.close()              # it's necessary to do it in block too, because reading is evented
            end
        end
    end
    
Support of Ruby API is limited to `#open`, `#close`, `#read` and `#write`
methods only, so for special operations use simply:

    EM::File::open("some_file.txt", "r") do |io|
        io.native   # returns native Ruby File class object
    end
    
### Special Uses

It's possible to use also another IO objects than `File` object by 
giving appropriate IO instance instead of filename to methods:

    require "em-files"
    require "stringio"
    
    io = StringIO::new
    
    EM::run do
        EM::File::open(io) do |io|
            # some multiplexed operations
        end
    end
    
By this way you can also perform for example more time consuming
operations by simple way (if they can be processed in block manner) 
using filters:

    require "em-files"
    require "zlib"

    zip = Zlib::Deflate::new
    filter = Proc::new { |chunk| zip.deflate(chunk, Zlib::SYNC_FLUSH) }
    data = "..."    # some data bigger than big
    
    EM::run do
        EM::File::write(data, filter)   # done in several ticks
    end

    
Contributing
------------

1. Fork it.
2. Create a branch (`git checkout -b 20101220-my-change`).
3. Commit your changes (`git commit -am "Added something"`).
4. Push to the branch (`git push origin 20101220-my-change`).
5. Create an [Issue][2] with a link to your branch.
6. Enjoy a refreshing Diet Coke and wait.

Copyright
---------

Copyright &copy; 2011 [Martin Kozák][3]. See `LICENSE.txt` for
further details.

[1]: http://www.ruby-doc.org/core/classes/File.html
[2]: http://github.com/martinkozak/em-files/issues
[3]: http://www.martinkozak.net/
[4]: http://rubyeventmachine.com/

EventMachine Files
==================

**em-file** solves problem of blocking disk IO while operating with 
large files. Uses [EventMachine][4] for multiplexing reads and writes
to small blocks performed in standalone EM ticks. It speeds down the
file IO operations of sure, but allows running other tasks with them 
simultaneously from EM point of view.

API is similar to classic Ruby file IO represented by [File][1] class.
See an example:

    require "em-file"
    EM::File::open("some_file.txt", "r") do |io|
        io.read(1024) do |data|     # writing works by very similar way, of sure
            puts data
            io.close()              # it's necessary to do it in block too, because reading is evented
        end
    end
    
Support of Ruby API is limited to `#open`, `#close`, `#read` and `#write`
methods only, so for special operations use simply:

    EM::File::open("some_file.txt", "r") do |io|
        io.native   # returns native Ruby File class object
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

[2]: http://github.com/martinkozak/em-sequence/issues
[3]: http://www.martinkozak.net/
[4]: http://rubyeventmachine.com/

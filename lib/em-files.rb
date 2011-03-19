# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net)

require "eventmachine"

##
# Main EventMachine module.
# @see http://rubyeventmachine.com/
#

module EM

    ##
    # Sequenced file reader and writer.
    #
    
    class File
    
        ##
        # Holds the default size of block operated during one tick.
        #
        
        RWSIZE = 65536

        ##
        # Opens the file.
        #
        # In opposite to appropriate Ruby method, "block syntax" is only
        # syntactic sugar, file isn't closed after return from block
        # because processing is asynchronous so it doesn't know when 
        # is convenient to close the file.
        #
        # @param [String] filepath path to file
        # @param [String] mode file access mode (see equivalent Ruby method)
        # @param [Integer] rwsize size of block operated during one tick
        # @param [Proc] block syntactic sugar for wrapping File access object
        # @return [File] file access object
        #

        def self.open(filepath, mode = "r", rwsize = self::RWSIZE, &block)   # 64 kilobytes
            rwsize = self::RWSIZE if rwsize.nil?
            
            file = self::new(filepath, mode, rwsize)
            if not block.nil?
                block.call(file)
            end
            
            return file
        end
        
        ##
        # Reads whole content of the file. Be warn, it reads it in 
        # binary mode. If IO object is given instead of filepath, uses 
        # it as native one and +mode+ argument is ignored.
        #
        # @param [String] filepath path to file
        # @param [Integer] rwsize size of block operated during one tick
        # @param [Proc] filter filter which for postprocessing each 
        #   read chunk
        # @param [Proc] block block for giving back the result
        #
        
        
        def self.read(filepath, rwsize = self::RWSIZE, filter = nil, &block)
            rwsize = self::RWSIZE if rwsize.nil?
            self::open(filepath, "rb", rwsize) do |io|
                io.read(nil, filter) do |out|
                    io.close()
                    block.call(out)
                end
            end
        end
        
        ##
        # Writes data to file and closes it. Writes them in binary mode. 
        # If IO object is given instead of filepath, uses it as native 
        # one and +mode+ argument is ignored.
        #
        # @param [String] filepath path to file
        # @param [String] data data for write
        # @param [Integer] rwsize size of block operated during one tick
        # @param [Proc] filter filter which for preprocessing each 
        #   written chunk
        # @param [Proc] block block called when writing is finished with
        #   written bytes size count as parameter
        #
        
        def self.write(filepath, data = "", rwsize = self::RWSIZE, filter = nil, &block)
            rwsize = self::RWSIZE if rwsize.nil?
            self::open(filepath, "wb", rwsize) do |io|
                io.write(data, filter) do |length|
                    io.close()
                    block.call(length)
                end
            end
        end
        
        ###
        
        ##
        # Holds file object.
        # @return [IO]
        #
        
        attr_accessor :native
        @native
        
        ##
        # Indicates block size for operate with in one tick.
        # @return [Integer]
        #
        
        attr_accessor :rw_len
        @rw_len
        
        ##
        # Holds mode of the object.
        # @return [String]
        #
        
        attr_reader :mode
        @mode
        
        ##
        # Constructor. If IO object is given instead of filepath, uses 
        # it as native one and +mode+ argument is ignored.
        #
        # @param [String, IO] filepath path to file or IO object
        # @param [String] mode file access mode (see equivalent Ruby method)
        # @param [Integer] rwsize size of block operated during one tick
        #
                
        def initialize(filepath, mode = "r", rwsize = self.class::RWSIZE)
            @mode = mode
            @rw_len = rwsize
            
            rwsize = self::RWSIZE if rwsize.nil?
            
            # If filepath is directly IO, uses it
            if filepath.kind_of? IO
                @native = filepath
            else
                @native = ::File::open(filepath, mode)
            end
            
        end

        ##
        # Reads data from file.
        #
        # It will reopen the file if +EBADF: Bad file descriptor+ of 
        # +File+ class IO object will occur.
        #
        # @overload read(length, &block)
        #   Reads specified amount of data from file.
        #   @param [Integer] length length for read from file
        #   @param [Proc] filter filter which for postprocessing each 
        #       read chunk
        #   @param [Proc] block callback for returning the result
        # @overload read(&block)
        #   Reads whole content of file.
        #   @param [Proc] filter filter which for processing each block
        #   @param [Proc] block callback for returning the result
        #
        
        def read(length = nil, filter = nil, &block)
            buffer = ""
            pos = 0
            
            # Arguments
            if length.kind_of? Proc
                filter = length
            end
            
            
            worker = Proc::new do
            
                # Sets length for read
                if not length.nil?
                    rlen = length - buffer.length
                    if rlen > @rw_len
                        rlen = @rw_len
                    end
                else
                    rlen = @rw_len
                end
                
                # Reads
                begin
                    chunk = @native.read(rlen)
                    if not filter.nil?
                        chunk = filter.call(chunk)
                    end
                    buffer << chunk
                rescue Errno::EBADF
                    if @native.kind_of? ::File
                        self.reopen!
                        @native.seek(pos)
                        redo
                    else
                        raise
                    end
                end
                
                pos = @native.pos
                
                # Returns or continues work
                if @native.eof? or (buffer.length == length)
                    if not block.nil?
                        block.call(buffer)              # returns result
                    end
                else
                    EM::next_tick { worker.call() }     # continues work
                end
                
            end
            
            worker.call()
        end
        
        ##
        # Reopens the file with the original mode.
        #
        
        def reopen!
            @native = ::File.open(@native.path, @mode)
        end
        
        ##
        # Writes data to file.
        #
        # It will reopen the file if +EBADF: Bad file descriptor+ of 
        # +File+ class IO object will occur.
        #
        # @param [String] data data for write
        # @param [Proc] filter filter which for preprocessing each 
        #   written chunk
        # @param [Proc] block callback called when finish and for giving
        #   back the length of written data
        #
        
        def write(data, filter = nil, &block)
            written = 0
            pos = 0
            
            worker = Proc::new do
            
                # Writes
                begin
                    chunk = data[written...(written + @rw_len)]
                    if not filter.nil?
                        chunk = filter.call(chunk)
                    end
                    written += @native.write(chunk)
                rescue Errno::EBADF
                    if @native.kind_of? File
                        self.reopen!
                        @native.seek(pos)
                        redo
                    else
                        raise
                    end
                end
            
                pos = @native.pos
                
                # Returns or continues work
                if written >= data.bytesize
                    if not block.nil?
                        block.call(written)             # returns result
                    end
                else
                    EM::next_tick { worker.call() }     # continues work
                end
                
            end
            
            worker.call()
        end
        
        ##
        # Closes the file.
        #
        
        def close
            @native.close
        end
    end
end

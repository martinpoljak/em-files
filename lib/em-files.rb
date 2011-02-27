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

        def self.open(filepath, mode = "r", rwsize = 65536, &block)   # 64 kilobytes
            file = self::new(filepath, mode, rwsize)
            if not block.nil?
                block.call(file)
            end
            
            return file
        end
        
        ##
        # Reads wholoe content of the file.
        #
        # @param [String] filepath path to file
        # @param [Integer] rwsize size of block operated during one tick
        # @param [Proc] block block for giving back the result
        #
        
        
        def self.read(filepath, rwsize = 65536, &block)
            self::open(filepath, "r", rwsize) do |io|
                io.read do |out|
                    block.call(out)
                    io.close()
                end
            end
        end
        
        ##
        # Writes data to file and closes it.
        #
        # @param [String] filepath path to file
        # @param [String] data data for write
        # @param [Integer] rwsize size of block operated during one tick
        # @param [Proc] block block called when writing is finished with
        #   written bytes size count as parameter
        #
        
        def self.write(filepath, data = "", rwsize = 65536, &block)
            self::open(filepath, "w", rwsize) do |io|
                io.write(data) do |length|
                    block.call(length)
                    io.close()
                end
            end
        end
        
        ###
        
        ##
        # Holds file object.
        # @return [::File]
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
        # Constructor.
        #
        # @param [String] filepath path to file
        # @param [String] mode file access mode (see equivalent Ruby method)
        # @param [Integer] rwsize size of block operated during one tick
        #
                
        def initialize(filepath, mode = "r", rwsize = 65536)
            @native = ::File::open(filepath, mode)
            @rw_len = rwsize
        end

        ##
        # Reads data from file.
        #
        # @overload read(length, &block)
        #   Reads specified amount of data from file.
        #   @param [Integer] length length for read from file
        #   @param [Proc] block callback for returning the result
        # @overload read(&block)
        #   Reads whole content of file.
        #   @param [Proc] block callback for returning the result
        #
        
        def read(length = nil, &block)
            buffer = ""
            
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
                buffer << @native.read(rlen)
                
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
        # Writes data to file.
        #
        # @param [String] data data for write
        # @param [Proc] block callback called when finish and for giving
        #   back the length of written data
        #
        
        def write(data, &block)
            written = 0
            
            worker = Proc::new do
            
                # Writes
                written += @native.write(data[written...(written + @rw_len)])
            
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

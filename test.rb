#!/usr/bin/ruby
# encoding: utf-8
# (c) 2011 Martin Kozák

$:.push("./lib")
require 'em-files'
require "riot"

test = Array::new(5)

EM::run do

    # Test 1
    test[0] = EM::File::open("./~test1", "w")
    test[0].close()
    
    # Test 2
    EM::File::open("./~test1", "w") do |io|
        io.write("x" * 300000) do |len|
            test[1] = len
            io.close()
        end
    end

    EM::add_timer(1) do
        # Test 3
        EM::File::open("./~test1", "r") do |io|
            io.read do |data|
                test[2] = data
                io.close()
            end
        end
    end
    
    # Test 4
    EM::File::write("./~test2", "x" * 300000) do |len|
        test[3] = len
    end
    
    EM::add_timer(1) do
        # Test 5
        EM::File::read("./~test2") do |data|
            test[4] = data
        end
    end
    
    EM::add_timer(2) do 
        EM::stop
    end
    
end


context "EM::Files (instance methods)" do
    setup { test }
    
    asserts("#open returns EM::File object") do 
        topic[0].kind_of? EM::File
    end
    asserts("file size produced by #write is equivalent to reported written data length") do 
        topic[1] == File.size?("./~test1")
    end
    asserts("file content produced by #write is correct and #read works well") do
        topic[2] == "x" * 300000
    end
    
    teardown do 
        File.unlink("./~test1")
    end
end

context "EM::Files (class methods)" do
    setup { test }
    
    asserts("file size produced by #write is equivalent to reported written data length") do 
        topic[1] == File.size?("./~test2")
    end
    asserts("file content produced by #write is correct and #read works well") do
        topic[2] == "x" * 300000
    end
    
    teardown do 
        File.unlink("./~test2")
    end
end

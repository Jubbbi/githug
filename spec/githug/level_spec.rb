require 'spec_helper'
require 'grit'

describe Githug::Level do
  
  before(:each) do
    @file = <<-eof
difficulty 1
description "A test description"
setup do
  "test"
end
solution do
  Grit::Repo.new("githug/notadir")
end

hints [
  "this is hint 1",
  "this is hint 2"]

hint do
  puts "this is a hint"
end
    eof
    File.stub(:exists?).and_return(true)
    File.stub(:read).and_return(@file)
    @level = Githug::Level.load("init")
    @repo = mock
    @repo.stub(:reset) 
    Githug::Repository.stub(:new).and_return(@repo)
    Githug::UI.stub(:puts)
    Githug::UI.stub(:print)
  end

  it "should mixin UI" do
    Githug::Level.ancestors.should include(Githug::UI)
  end


  describe "load" do
    
    it "should load the level" do
      File.stub(:dirname).and_return("")
      File.should_receive(:read).with('/../../levels/init.rb').and_return(@file)
      level = Githug::Level.load("init")
      level.instance_variable_get("@difficulty").should eql(1)
      level.instance_variable_get("@description").should eql("A test description")
    end

    it "should return false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.load(1).should eql(false)
    end

    describe "internationalization" do

      it "should have a different description if a translation is availble" do
        I18n.stub(:locale).and_return(:de)
        I18n.stub(:exists?).and_return(true)
        I18n.stub(:t)
        I18n.should_receive(:t).with("level.init.description").and_return("Ein Test Beschreibung")
        level = Githug::Level.load("init")
        level.instance_variable_get("@description").should eql("Ein Test Beschreibung")
      end

      it "should use the English translation if none is available" do
        I18n.stub(:locale).and_return(:de)
        I18n.stub(:exists?).and_return(false)
        I18n.should_not_receive(:t)
        level = Githug::Level.load("init")
        level.instance_variable_get("@description").should eql("A test description")
      end

    end

  end

  describe "load_from_file" do
    it "should load the level" do
      File.stub(:dirname).and_return("")
      File.should_receive(:read).with('/foo/bar/test/level.rb').and_return(@file)
      level = Githug::Level.load_from_file("/foo/bar/test/level.rb")
      level.instance_variable_get("@difficulty").should eql(1)
      level.instance_variable_get("@description").should eql("A test description")
    end

    it "should return false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.load_from_file("/foo/bar/test/level.rb").should eql(false)
    end
  end

  describe "setup" do

    it "should return false if the level does not exist" do
      File.stub(:exists?).and_return(false)
      Githug::Level.setup("/foo/bar/test/level.rb").should eql(false)
    end

  end


  describe "solve" do
    
    it "should solve the problem" do
      @level.solve.should eql(false)
    end

    it "should return true if the requirements have been met" do
      Grit::Repo.stub(:new).and_return(true) 
      @level.solve.should eql(true)
    end

  end

  describe "test" do
    it "should call solve" do
      @level.instance_variable_get("@solution").should_receive(:call) 
      @level.test
    end  
  end


  describe "full_description" do

    it "should display a full description" do
      Githug::UI.stub(:puts)
      Githug::UI.should_receive(:puts).with("Level: 1")
      Githug::UI.should_receive(:puts).with("Difficulty: *")
      Githug::UI.should_receive(:puts).with("A test description")
      @level.full_description
    end

  end

  describe "setup" do

    it "should call setup" do
      @level.setup_level.should eql("test") 
    end

    it "should not call the setup if none exists" do
      @level.instance_variable_set("@setup", nil)
      lambda {@level.setup_level}.should_not raise_error(NoMethodError)
    end

  end
  

  describe "repo" do
      
    it "should initialize a repository when repo is called" do
      @level.repo.should equal(@repo)
      Githug::Repository.should_not_receive(:new)
      @level.repo.should equal(@repo)
    end

    it "should call reset on setup_level" do
      @repo.should_receive(:reset) 
      @level.setup_level
    end

  end

  describe "request" do
    describe "When the language is English" do
      it "should delegate to UI.request with the same message" do
        I18n.stub(:locale).and_return(:en)
        Githug::UI.should_receive(:request).with("A request")
        @level.request("A request")
      end
    end

    describe "When the language is not English" do
      before(:each) do
        I18n.stub(:locale).and_return(:de)
      end

      describe "when the translation is missing" do
        it "should delegate to UI.request with the same message" do
          I18n.stub(:exists?).and_return(false)
          Githug::UI.should_receive(:request).with("A request")
          @level.request("A request")
        end
      end

      describe "when the translation is present" do
        it "should delegate to UI.request with the translated" do
          I18n.stub(:exists?).and_return(true)
          I18n.should_receive(:t).with("level.init.requests").and_return(["Translated Request 1", "Translated Request 2"])
          Githug::UI.should_receive(:request).with("Translated Request 1")
          @level.request("A request")
          Githug::UI.should_receive(:request).with("Translated Request 2")
          @level.request("Another request")
        end
      end

    end
  end

  describe "hint" do
    
    before(:each) do
      @profile = mock.as_null_object
      Githug::Profile.stub(:load).and_return(@profile)
      @profile.stub(:current_hint_index).and_return(0,0,1,0)
    end

    it "should return sequential hint if there are multiple" do
      @level.should_receive(:puts).ordered.with("this is hint 1")
      @level.show_hint
      
      @level.should_receive(:puts).ordered.with("this is hint 2")
      @level.show_hint
      
      @level.should_receive(:puts).ordered.with("this is hint 1")
      @level.show_hint
    end

    it "should display a hint if there are not multiple" do
      @level.instance_variable_set("@hints", nil)
      @level.should_receive(:puts).with("this is a hint")
      @level.show_hint 
    end

    it "should not call the hint if none exist" do
      @level.instance_variable_set("@hint", nil)
      lambda {@level.show_hint}.should_not raise_error(NoMethodError)
    end
  end

  describe "init_from_level" do
    it "should copy the files from the level folder" do
      FileUtils.should_receive(:cp_r).with("#{@level.level_path}/.", ".") 
      FileUtils.should_receive(:mv).with(".githug", ".git")
      @level.init_from_level
    end  
  end
end

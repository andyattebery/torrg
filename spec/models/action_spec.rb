require File.dirname(__FILE__) + '/../../models/action'


TEST_FILE_DIR = File.expand_path('../testfiles/') + '/'

describe Action do
  
  it "should instantiate a UnrarAction object if the directory contains a " + 
      ".part01.rar file" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-partXX')
    action.should be_instance_of UnrarAction
  end
  
  it "should instantiate a UnrarAction object if the directory contains a " + 
      ".rar file" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-rXX')
    action.should be_instance_of UnrarAction
  end
  
  it "should instantiate a UnrarAction object if the directory contains a " + 
      ".avi file" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-avi')
    action.should be_instance_of MoveAction
  end
  
  it "should instantiate a UnrarAction object if the directory contains a " + 
      ".mkv file" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-mkv')
    action.should be_instance_of MoveAction
  end
  
  it "should recurse if directories are found" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01-02.dvdrip-group')
  end
  
end

describe UnrarAction do
  it "should unrar files like partXX.rar"  do
    
  end
  
  it "should unrar file to the destination directory" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-rXX')
  end
end

describe MoveAction do
  before(:all) do
    Dir.chdir(TEST_FILE_DIR)
    working_files = Dir.glob("*")
    working_files.delete("_original")
    FileUtils.rm_r(working_files, :verbose => true)
    Dir.chdir("_original")
    FileUtils.cp_r(Dir.glob("*"), "..", :verbose => true)
  end
  
  it "should copy video file and extras, delete originals, and symlink back" do
    action = Action.new(TEST_FILE_DIR + 'test.name.s01e01.hdtv-group-mkv')
    action.execute(File.expand_path(TEST_FILE_DIR + 'dst'))
  end
end
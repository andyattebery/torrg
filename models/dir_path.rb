SINGLE_DIR = 
TWO_LEVEL_DIR = 
THREE_LEVEL_DIR = 

class DirPath
  def self.new(path)
    klass = determine_class(path)
    @@file_path = File.expand_path(@file_list[0])
    klass == self ? super() : klass.new(path)
  end

  def execute(path)
    NotImplementedError
  end

  private

end

class SingleDirPath < DirPath
  def new
    super
  end
  
  def execute(path)
  end
end

class TwoLevelDirPath < DirPath
  def new
    super
  end
  
  def execute(path)
  end
end

class ThreeLevelDirPath < DirPath
  def new
    super
  end
  
  def execute(path)
  end
end

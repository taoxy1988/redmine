class CompileController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  helper :sort
  include SortHelper

  def index
    sort_init 'asc'
    sort_update %w()

    @identifier = Project.find(@project)
    project_id = @identifier.id
    @compile = Compile.find(:all,:conditions=>"project_id = '#{project_id}'")
    @compile.each do |compile|
      if(compile.branches == 'trunk'||compile.branches == 'HEAD')
          compile.branches='主线'
      end
    end
  end

  def new
    identifier = Project.find(@project)
    project_id = identifier.id
    @trunk = Trunk.find(:all,:conditions=>"project_id = '#{project_id}' and createdate != 'tags'")
    @trunk.each do |trunk|
      puts trunk.branches
       if(trunk.branches == "trunk"||trunk.branches == 'HEAD'||trunk.branches == nil)
         trunk.branches = '主线'
       end
    end
    if request.post?
      if(params[:new]==nil || params[:new] == "")
        flash[:notice] = "输入不能为空！！！"
        redirect_to :controller => 'compile', :action => 'index', :id => @project
      else
        @produce = Compile.find(:all,:conditions=>"produce = '#{params[:new]}' and branches = '#{params[:trunk]}' ")
        if (@produce.count > 0)
             flash[:notice] = "产品已经被创建过！！！"
             redirect_to :controller => 'compile', :action => 'index', :id => @project
        else
          @identifier = Project.find(@project)
          project_id = @identifier.id
          e = params[:trunk]
          if(e == "trunk"||e == 'HEAD'||e == nil||e == "主线")
              e = "HEAD"
          end
          @compile = Compile.new(:project_id => project_id,:produce => params[:new],:branches => e)
          if @compile.save
            flash[:notice] = "创建成功！"
            redirect_to :controller => 'compile', :action => 'index', :id => @project
          end
        end
       end
    end
  end

  def destroy
    @compile = Compile.find_by_produce(params[:produce])
    @compile.destroy
    flash[:notice] = "删除成功！"
    redirect_to :controller => 'compile', :action => 'index', :id => @project
  end

  def add
    @propuct = params[:produce]
    @branches = params[:branches]
    if request.post?
      t = Time.new
      date = t.strftime("%Y-%m-%d %H:%M:%p")

      @user = User.find(User.current)
      puts @user.login

      @identifier = Project.find(@project)

      @publiclib = Publiclib.new(:project_id => @identifier.id,:username => @user.login,:reserved3=> params[:reserved3],
                   :releasedate => date,:releaseversion => params[:releaseversion],:releasenote => params[:releasenote],
                   :reserved1 => params[:reserved1],:reserved2 => '12345678')
      if @publiclib.save
        redirect_to :controller => 'compile',:action => 'docompile',:id => @project,:produce =>params[:reserved1],:branches => params[:reserved3]
      end
    end
  end

  def docompile
    t = Time.new
    date = t.strftime('%Y-%m-%d-%H:%M:%S')

    puts date
    ramdom = newpass(10)
    puts ramdom

    @user = User.find(User.current)
    puts @user.login

    @identifier = Project.find(@project)
    @branches = params[:branches]
    @propuct = params[:produce]
    @repository = params[:repository]
    @servername = params[:servername]
    if(@branches == "主线")
      @branches = "HEAD"
    end

    if((@identifier.identifier == "lotus"))
      a = "/opt/ioa/bbb/" + @repository + "/"
    else
      a = "/opt/ioa/bbb/svn/"
    end

    if File.directory? a
    else
      Dir.mkdir(a)
    end

    @identifier = Project.find(@project)
    b = a + @identifier.identifier
    project_id = @identifier.id
    puts b
    if File.directory? b
    else
      Dir.mkdir(b)
    end

    @propuct = params[:produce]
    @showpathdir = @branches
    c = b + "/" + @showpathdir
    if File.directory? c
    else
      Dir.mkdir(c)
    end
    @addp = c + "/" + @propuct
    if File.directory? @addp
    else
      Dir.mkdir(@addp)
    end

    d = date + "-" + ramdom + "-" + @user.login
    @e = @addp + "/" + d
    puts d
    puts @e

    if File.directory? @e
    else
      Dir.mkdir(@e)
    end

    if((@branches == "trunk")||(@branches == "主线")||(@branches == "HEAD")||(@branches==nil))
    	 @m = "tag=HEAD"
    	 trunks = Trunk.find_by_sql("select trunk from trunks where createdate = 'trunk' and project_id = '#{project_id}'")
      	temp = trunks[0]
    	 #p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/trunk"
    	 p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/trunk"
    	 svnpath="http://mcv.inspur.com/svn/"+ temp.trunk + "/trunk"
    else
    	 brachesname = @branches
      trunks = Trunk.find_by_sql("select trunk from trunks where branches = '#{brachesname}' and project_id = '#{project_id}'")
      temp = trunks[0]
      @m = "tag=" + params[:branches]
      #p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/branches/" + @branches
    	 p = "svnpath=http://mcv.inspur.com/svn/"+ temp.trunk + "/branches/" + @branches
      svnpath="http://mcv.inspur.com/svn/"+ temp.trunk + "/branches/" + @branches 
    end

   if ((@identifier.identifier == "lotus"))
      require "rubygems"
      require "mysql"

         puts "++++++++++++++++++++++++++++++++++"
      p = svnpath;
      @option = params[:option]
      db = Mysql.real_connect('127.0.0.1', 'inspur', 'inspur123456', 'JOBS')
       puts "!!!!!!!!!!!!!!!!!!!!!!!!!!++!!!"
      table = "job"
      db.query("insert into #{table} (ID,code,code_type,branch,product,os,hostname,url,status,cancel,get_res,mail_to,path,output,usrname,compile) values('','#{@identifier.identifier}','#{@repository}','#{@branches}','#{@propuct}','#{@servername}','','','not_start','hold','no','','#{p}','#{@e}','#{d}','#{@option}')")
      db.close
 puts "!!!!!!!!!!!!!!!======!!!!!!!!!!!!!!"

      @outpath = "http://mcv.inspur.com/bbb/" + @repository + "/" +@identifier.identifier+"/"+@branches+"/"+@propuct+"/"+d
      @logpath = "http://mcv.inspur.com/bbb/" + @repository + "/" +@identifier.identifier+"/"+@branches+"/"+@propuct+"/"+d+"/BUILD.LOG"

    else
      f = a + "redmine/"
      if File.directory? f
      else
        Dir.mkdir(f)
      end
      puts f

      g = f + ramdom + "svn.redmine"
      h = g + ".tmp"
      puts g

      fd = File.new(h, "w+")

      i = "src=" + temp.trunk
      j = "product=" + @propuct
      k = "PathOutput=" + @e
      l = "user=tmp\n"

      n = "name=" + @identifier.name

      # @o = Repository.find_by_project_id(@identifier.id)
      # puts @o
      # p = "svnpath=" + @o.url

      fd.puts i
      fd.puts j
      fd.puts k
      fd.puts l
      fd.puts @m
      fd.puts n
      fd.puts p
      fd.close

      File.rename( h, g )

      @outpath = "http://mcv.inspur.com/bbb/svn/"+@identifier.identifier+"/"+@showpathdir+"/"+@propuct+"/"+d
      @logpath = "http://mcv.inspur.com/bbb/svn/"+@identifier.identifier+"/"+@showpathdir+"/"+@propuct+"/"+d+"/BUILD.LOG"
    end

     puts @outpath
     puts @logpath

     @publiclib = Publiclib.find(:all,:conditions=>"reserved2 = '12345678'")

     @publiclib.each do |publiclib|
       publiclib.reserved2 = @outpath
       publiclib.save
     end
     flash[:notice] = "正在进行编译！"

  end

  def canclecompile
    @output = params[:outpath]
    require "rubygems"
    require "mysql"
    db = Mysql.real_connect('127.0.0.1', 'inspur', 'inspur123456', 'JOBS')
    #db.options(Mysql::SET_CHARSET_NAME, 'utf8')
    table = "job"
    db.query("update #{table} set cancel='cancel' where output='#{@output}'")
    db.close
    redirect_to :controller => 'compile', :action => 'index', :id => @project
    flash[:notice] = "编译已取消！"
  end

  def compileoption
    @branches = params[:branches]
    @propuct = params[:produce]

    @identifier = Project.find(@project)
	   if ((@identifier.identifier == "lotus"))
	     @option1 = "1.compile MBoot"
	     @option2 = "2.compile Kernel and copy zImage to android system"
	     @option3 = "3.compile Supernova and copy to tftp image directory"
	     @option4 = "4.compile android and copy to tftp image directory"
	     @option5 = "5.compile ddi,you should update the library manually && you should confrim istb3 svn code ready!!!"
	     @option6 = "6.compile ALL and prepare all the tftp image"
	   else
	     @option1 = "1.compile SDK"
	     @option2 = "2.compile qt"
	     @option3 = "3.compile thirpart lib"
	     @option4 = "4.compile all part"
	     @option5 = "5.compile the svn tree"
	     @option6 = "6.only create the image"
	   end
	    if request.post?
	      puts params[:repository]
	      puts params[:chooseoption]
	      puts @project
	      puts @propuct
	      puts @branches
	      @chooseoption = params[:chooseoption]
	      @repository = params[:repository]
	      @servername = params[:servername]
	      redirect_to :controller => 'compile', :action => 'docompile', :id => @project, :produce => @propuct, :branches => @branches, :option => @chooseoption,:repository =>@repository,:servername => @servername
	    end
  end

  def choose
    @identifier = Project.find(@project)
    @branches = params[:branches]
    @propuct = params[:produce]

    if(@identifier.identifier == "lotus")
      redirect_to :controller => 'compile', :action => 'compileoption', :id => @project, :produce => @propuct,:branches => @branches
    else
      redirect_to :controller => 'compile', :action => 'docompile', :id => @project, :produce => @propuct, :branches => @branches, :option => 0 ,:repository => 'svn',:servername => 'linux'
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id])
  end

  def newpass(len)
    newpass = ""
    1.upto(len){ |i| newpass << rand(10).to_s}
    return newpass
  end
end

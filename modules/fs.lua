-- based on https://oc.cil.li/index.php?/topic/844-serverfs-host-a-filesystem-over-the-network/

local drawing = require("khrd.drawing")
local core = require("khrd.core")
local component = require("component")
local computer = require("computer")
local serialization = require("serialization")
local fs = require("filesystem")

local module = {
  name = "FS"
}

local Mod = {}
Mod.__index = Mod

function Mod.create(cfg)
  local data = {}
  setmetatable(data, Mod)
  data.ctx = nil
  data.cfg = cfg.mod.fs
  data.file_systems = {}
  
  for address in component.list("filesystem") do
    local thisComponent = component.proxy(address)
    data.file_systems[address] = {
      component = thisComponent,
      primary = address ~= computer.getBootAddress(),
      temp = address ~= computer.tmpAddress()
    }
  end
  return data
end

function Mod:init_visual(ctx)
  self.ctx = ctx
end

function Mod:draw_view(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "FS")
end

function Mod:key_down(menu, char, code)
end

function Mod:key_up(menu, char, code)
end

function Mod:update()
end

function module.init(cfg)
  return Mod.create(cfg)
end

function module.make_fs_proxy()
  local fs_proxy = {
    type = "filesystem",
    address = "0000-vfs"
  }
end

  --   filesystem.isAutorunEnabled(): boolean
  --   Returns whether autorun is currently enabled. If this is true, newly mounted file systems will be checked for a file named autorun[.lua] in their root directory. If such a file exists, it is executed.
   
  --   filesystem.setAutorunEnabled(value: boolean)
  --   Sets whether autorun files should be ran on startup.
    
  --   filesystem.canonical(path: string): string
  --   Returns the canonical form of the specified path, i.e. a path containing no “indirections” such as . or ... For example, the paths /tmp/../bin/ls.lua and /bin/./ls.lua are equivalent, and their canonical form is /bin/ls.lua.
  --   Note that this function truncates relative paths to their topmost “known” directory. For example, ../bin/ls.lua becomes bin/ls.lua. It stays a relative path, however - mind the lack of a leading slash.
  
  --   filesystem.segments(path: string): table
  --   Returns a table containing one entry for each canonical segment of the given path. Examples:
  --       filesystem.segments("foo/bar") → {"foo","bar"}
  --       filesystem.segments("foo/bar/../baz") → {"foo","baz"}
        
  --   filesystem.concat(pathA: string, pathB: string[, ...]): string
  --   Concatenates two or more paths. Note that all paths other than the first are treated as relative paths, even if they begin with a slash. The canonical form of the resulting concatenated path is returned, so fs.concat("a", "..") results in an empty string.
   
  --  filesystem.path(path: string): string
  --   Returns the path component of a path to a file, i.e. everything before the last slash in the canonical form of the specified path.
   
  --   filesystem.name(path: string): string
  --   Returns the file name component of a path to a file, i.e. everything after the last slash in the canonical form of the specified path.
   
  --   filesystem.proxy(filter: string): table or nil, string
  --   This is similar to component.proxy, except that the specified string may also be a file system component's label. We check for the label first, if no file system has the specified label we fall back to component.proxy. Returns the proxy of the specified file system, or nil and an error message if no file system matching the specified filter was found.
  --   filesystem.mount(fs: table or string, path: string): boolean or nil, string
  --   Mounts a file system at the specified path. The first parameter can be either a file system component's proxy, its address or its label. The second is a path into the global directory tree. Returns true if the file system was successfully mounted, nil and an error message otherwise.
  --   filesystem.mounts(): function -> table, string
   
  --   Returns an iterator function over all currently mounted file system component's proxies and the paths at which they are mounted. This means the same proxy may appear multiple times, but with different mount paths.
  --   filesystem.umount(fsOrPath: table or string): boolean
  --   Unmounts a file system. The parameter can either be a file system component's proxy or (abbreviated) address, in which case all mount points of this file system will be removed, or a path into the global directory structure, in which case the file system mount containing that directory will be unmounted.
   
  --   filesystem.isLink(path: string): boolean[, string]
  --   Checks if the object at the specified path is a symlink, if so returns the path to where it links (as of 1.3.3).
   
  --   filesystem.link(target: string, linkpath: string): boolean or nil, string
  --   Creates a symbolic link to the specified target path at the specified path. This is a 'soft' link, i.e. it the target file does not actually have to exist at the time of creation, and the link will not be deleted if the target file is deleted. Symbolic links do not persist across reboots.
  
  --   filesystem.get(path: string): table, string or nil, string
  --   Gets the file system component's proxy that contains the specified path. Returns the proxy and mount path, or nil and an error message.
  
  --   filesystem.exists(path: string): boolean
  --   Checks whether a file or folder exist at the specified path.
    
  --   filesystem.size(path: string): number
  --   Gets the file size of the file at the specified location. Returns 0 if the path points to anything other than a file.
    
  --   filesystem.isDirectory(path: string): boolean
  --   Gets whether the path points to a directory. Returns false if not, either because the path points to a file, or file.exists(path) is false.
    
  --   filesystem.lastModified(path: string): number
  --   Returns the real world unix timestamp of the last time the file at the specified path was modified. For directories this is usually the time of their creation.
    
  --   filesystem.list(path: string): function -> string or nil, string
  --   Returns an iterator over all elements in the directory at the specified path. Returns nil and an error messages if the path is invalid or some other error occurred.
  --   Note that directories usually are postfixed with a slash, to allow identifying them without an additional call to fs.isDirectory.
   
  --   filesystem.makeDirectory(path: string): boolean or nil, string
  --   Creates a new directory at the specified path. Creates any parent directories that do not exist yet, if necessary. Returns true on success, nil and an error message otherwise.
    
  --   filesystem.remove(path: string): boolean or nil, string
  --   Deletes a file or folder. If the path specifies a folder, deletes all files and subdirectories in the folder, recursively. Return true on success, nil and an error message otherwise.
   
  --   filesystem.rename(oldPath: string, newPath: string): boolean or nil, string
  --   Renames a file or folder. If the paths point to different file system components this will only work for files, because it actually perform a copy operation, followed by a deletion if the copy succeeds.
  --   Returns true on success, nil and an error message otherwise.
    
  --   filesystem.copy(fromPath: string, toPath: string): boolean or nil, string
  --   Copies a file to the specified location. The target path has to contain the target file name. Does not support folders.
    
  --   filesystem.open(path: string[, mode: string]): table or nil, string
  --   Opens a file at the specified path for reading or writing. If mode is not specified it defaults to “r”. Possible modes are: r, rb, w, wb, a and ab.
  --   Returns a file stream (see below) on success, nil and an error message otherwise.
  --   Note that you can only open a limited number of files per file system at the same time. Files will be automatically closed when the garbage collection kicks in, but it is generally a good idea to call close on the file stream when done with the file.
  --       Important*: it is generally recommended to use io.open instead of this function, to get a buffered wrapper for the file stream.

  --   When opening files directly via the file system API you will get a file stream, a table with four functions. These functions are thin wrappers to the file system proxy's callbacks, which also means that read/write operations are not buffered, and can therefore be slow when reading few bytes often. You'll usually want to use io.open instead.
  --   file:close()
  --   Closes the file stream, releasing the handle on the underlying file system.
  --   file:read(n: number): string or nil, string
  --   Tries to read the specified number of bytes from the file stream. Returns the read string, which may be shorter than the specified number. Returns nil when the end of the stream was reached. Returns nil and an error message if some error occurred.
  --   file:seek(whence: string[, offset: number]): number or nil, string
  --   Jumps to the specified position in the file stream, if possible. Only supported by file streams opened in read mode. The first parameter determines the relative location to seek from and can be cur for the current position, set for the beginning of the stream and end for the end of the stream. The second parameter is the offset by which to modify the position. Returns the new position or nil and an error message if some error occurred.
  --   The default value for the second parameter is 0, so f:seek("set") will reset the position to the start of the file, f:seek("cur") will return the current position in the file.
  --   file:write(str: value): boolean or nil, string
  --   Writes the specified data to the stream. Returns true on success, nil and an error message otherwise.


return module
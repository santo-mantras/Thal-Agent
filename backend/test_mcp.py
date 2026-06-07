import asyncio
import os
from mcp import StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.session import ClientSession

async def main():
    print("Starting MCP Client...")
    server_params = StdioServerParameters(
        command="npx",
        args=["-y", "@modelcontextprotocol/server-gdrive"],
        env=os.environ.copy()
    )

    try:
        async with stdio_client(server_params) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()
                print("Session initialized.")
                
                # List tools
                tools_response = await session.list_tools()
                print("Available Tools:")
                for tool in tools_response.tools:
                    print(f"- {tool.name}: {tool.description}")
                    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())

""" Storage module for Aleph.
Basically manages the IPFS storage.
"""

import ipfsapi
import asyncio
import aiohttp

async def get_ipfs_api():
    from aleph.web import app
    host = app['config'].ipfs.host.value
    port = app['config'].ipfs.port.value

    return ipfsapi.connect(host, port)

async def get_json(hash):
    loop = asyncio.get_event_loop()
    api = await get_ipfs_api()
    result = await loop.run_in_executor(
        None, api.get_json, hash)
    return result

async def add_json(value):
    loop = asyncio.get_event_loop()
    api = await get_ipfs_api()
    result = await loop.run_in_executor(
        None, api.add_json, value)
    return result

async def add_file(fileobject, filename):
    async with aiohttp.ClientSession() as session:
        from nulsexplorer.web import app
        url = "http://%s:%d/api/v0/add" % (app['config'].ipfs.host.value,
                                 app['config'].ipfs.port.value)
        data = aiohttp.FormData()
        data.add_field('path',
                       fileobject,
                       filename=filename)

        resp = await session.post(url, data=data)
        return await resp.json()

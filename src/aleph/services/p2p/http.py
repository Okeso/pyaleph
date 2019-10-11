""" While our own streamer libp2p protocol is still unstable, use direct
HTTP connection to standard rest API.
"""

import aiohttp
import base64
from random import sample
from . import singleton
import logging
LOGGER = logging.getLogger('P2P.HTTP')

async def api_get_request(base_uri, method, timeout=1):
    async with aiohttp.ClientSession(read_timeout=timeout) as session:
        uri = f"{base_uri}/api/v0/{method}"
        try:
            async with session.get(uri) as resp:
                if resp.status != 200:
                    result = None
                else:
                    result = await resp.json()
        except:
            result = None
        return result


async def get_peer_hash_content(base_uri, item_hash, timeout=1):
    from aleph.web import app
    
    result = None
    item = await api_get_request(base_uri, f"storage/{item_hash}")
    if item is not None and item['status'] == 'success' and item['content'] is not None:
        # TODO: IMPORTANT /!\ verify the hash of received data!
        return base64.decodebytes(item['content'].encode('utf-8'))
    else:
        LOGGER.debug(f"can't get hash {item_hash}")

    return result
    
    
async def request_hash(item_hash):
    uris = sample(singleton.api_servers, k=len(singleton.api_servers))
    for uri in uris:
        content = await get_peer_hash_content(uri, item_hash)
        if content is not None:
            return content
        
    return None # Nothing found...
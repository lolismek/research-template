"""Tiny TCP relay: nb_relay.py <listen_port> <target_host> <target_port>.
Runs on the login node so localhost:<port> there reaches JupyterLab on the compute node."""
import asyncio, sys

async def pipe(r, w):
    try:
        while data := await r.read(65536):
            w.write(data); await w.drain()
    except Exception:
        pass
    finally:
        w.close()

async def handle(cr, cw):
    try:
        tr, tw = await asyncio.open_connection(HOST, TPORT)
    except Exception:
        cw.close(); return
    await asyncio.gather(pipe(cr, tw), pipe(tr, cw))

async def main():
    srv = await asyncio.start_server(handle, "127.0.0.1", LPORT)
    async with srv:
        await srv.serve_forever()

LPORT, HOST, TPORT = int(sys.argv[1]), sys.argv[2], int(sys.argv[3])
asyncio.run(main())

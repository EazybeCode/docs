# Download Images for Eazybe Documentation

Run this script in your `/images/` folder to download all required images:

```bash
#!/bin/bash
# Download all documentation images

# Revenue Inbox
curl -o unreplied-inbox.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1714150184/149a9d3f533bc30909c3b3bec2be/Screenshot+2025-09-08+at+10_16_29%E2%80%AFAM_spotlight.png"
curl -o critical-label.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1714152616/e873cfb982cb552e82dcdfe00b06/Screenshot+2025-09-08+at+10_14_25%E2%80%AFAM_spotlight+%282%29.png"
curl -o filter-controls.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1714154471/00ea7b5938a948371585d689464b/Screenshot+2025-09-08+at+10_27_55%E2%80%AFAM_spotlight.png"

# Labels
curl -o add-label-1.png "https://downloads.intercomcdn.com/i/o/1113048889/e767a9cba4e2ffe20ad22263/1.png"
curl -o add-label-2.png "https://downloads.intercomcdn.com/i/o/1113049106/96a87ebd52333527d3d6e652/2.png"
curl -o add-label-3.png "https://downloads.intercomcdn.com/i/o/1113049302/559a8047c833a87763eb08f8/3.png"
curl -o add-label-4.png "https://downloads.intercomcdn.com/i/o/1113049518/219966afcf390fd6e672270b/4.png"
curl -o add-label-5.png "https://downloads.intercomcdn.com/i/o/1113049922/354984ceb162a24c1f36471b/6.png"

# WABA
curl -o waba-window-open.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1589309753/d76476738b482857c691f21de09f/image.png"
curl -o waba-window-closed.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1589300920/bfff88d233e869e3e96daf800310/image.png"
curl -o waba-filter.png "https://downloads.intercomcdn.com/i/o/p2m2ant5/1589282163/2775fd5efd76ae6ae11eed7a3984/image.png"

echo "All images downloaded!"
```

Save as `download_images.sh`, make executable with `chmod +x download_images.sh`, and run.

Pixel = Struct.new(:r, :g, :b)
$img = Array.new(360) do
  Array.new(200) do Pixel.new(255,255,255) end  # ここで400x300の白い画像を作成
end
$cnt = 1000

#点を描く（透過機能付き）
def pset(x, y, r=0, g=0, b=0, a=0.0)
  if x < 0 || x >= 200 || y < 0 || y >= 360 then return end ### ここ変える
  $img[y][x].r = ($img[y][x].r * a + r * (1.0 - a)).to_i
  $img[y][x].g = ($img[y][x].g * a + g * (1.0 - a)).to_i
  $img[y][x].b = ($img[y][x].b * a + b * (1.0 - a)).to_i
end

#指定したファイル名のファイルに書き出す
def writeimagef(name)
  open(name, "wb") do |f|
    f.puts("P6\n200 360\n255")    ### ここかえる
    $img.each do |a| a.each do |p| f.write(p.to_a.pack('ccc')) end end
  end
end

#連続したファイル"img通し番号.ppm"に書き出す
def writeimage(name = "img#{$cnt}.ppm")
  open(name, "wb") do |f|
    f.puts("P6"); f.puts("200 360"); f.puts("255")  ### ここかえる
    $img.each do|a| a.each do |p| f.write(p.to_a.pack('ccc')) end end
  end
  $cnt += 1
end

#書き出した図のデータを一掃する
def clearimage
  $img.each do |a| a.each do |p| p[0] = p[1] = p[2] = 255 end end
end
#サイズを変更する場合、これより上の数字を修正

#四角形（透過機能付き）
def fillrect(x, y, w, h, r=0, g=0, b=0, a=0.0)
  j0 = (y-0.5*h).to_i; j1 = (y+0.5*h).to_i
  i0 = (x-0.5*w).to_i; i1 = (x+0.5*w).to_i
  j0.step(j1) do |j|
    i0.step(i1) do |i| pset(i, j, r, g, b, a) end
  end
end

#円（透過機能付き）
def fillcircle(x, y, rad, r=0, g=0, b=0, a=0.0)
  j0 = (y-rad).to_i; j1 = (y+rad).to_i
  i0 = (x-rad).to_i; i1 = (x+rad).to_i
  j0.step(j1) do |j|
    i0.step(i1) do |i|
      if (i-x)**2+(j-y)**2<rad**2 then pset(i,j,r,g,b,a) end
    end
  end
end

#楕円（透過機能付き）
def fillellipse(x, y, rx, ry, r=0, g=0, b=0, a=0.0)
  j0 = (y-ry).to_i; j1 = (y+ry).to_i
  i0 = (x-rx).to_i; i1 = (x+rx).to_i
  j0.step(j1) do |j|
    i0.step(i1) do |i|
      if (i-x).to_f**2/rx**2 + (j-y).to_f**2/ry**2 < 1.0
        pset(i, j, r, g, b, a)
      end
    end
  end
end

#三角形（透過機能付き）
def filltriangle(x0, y0, x1, y1, x2, y2, r=0, g=0, b=0, a=0.0)
  fillconvex([x0, x1, x2, x0], [y0, y1, y2, y0], r, g, b, a)
  fillconvex([x0, x2, x1, x0], [y0, y2, y1, y0], r, g, b, a)
end

#線を引く（透過機能付き）
def fillline(x0, y0, x1, y1, w, r=0, g=0, b=0, a=0.0)
  dx = y1-y0; dy = x0-x1; n = 0.5*w / Math.sqrt(dx**2 + dy**2)
  dx = dx * n; dy = dy * n
  fillconvex([x0-dx, x0+dx, x1+dx, x1-dx, x0-dx],[y0-dy, y0+dy, y1+dy, y1-dy, y0-dy], r, g, b, a)
end

#n度回転した楕円
def fillrotellipse(x, y, rx, ry, n, r=0, g=0, b=0, a=0.0)
  theta = n*(Math::PI/180)
  d = (if rx > ry then rx else ry end)
  j0 = (y-d).to_i; j1 = (y+d).to_i
  i0 = (x-d).to_i; i1 = (x+d).to_i
  j0.step(j1) do |j|
    i0.step(i1) do |i|
      dx = i - x; dy = j - y;
      px = dx*Math.cos(theta) - dy*Math.sin(theta)
      py = dx*Math.sin(theta) + dy*Math.cos(theta)
      if (px/rx)**2 + (py/ry)**2 < 1.0
        pset(i,j,r,g,b,a)
      end
    end
  end
end

#r1の太さのリング
def makering(x, y, rad, r1, r, g, b, a)
  j0 = (y-rad).to_i; j1 = (y+rad).to_i
  i0 = (x-rad).to_i; i1 = (x+rad).to_i
  j0.step(j1) do |j|
    i0.step(i1) do |i|
      if r1**2 <= (i-x)**2+(j-y)**2 && (i-x)**2+(j-y)**2<rad**2 then pset(i,j,r,g,b,a) end
    end
  end
end


#凸多角形を塗る（透過機能付き）
def fillconvex(ax, ay, r=0, g=0, b=0, a=0.0)
  xmax = ax.max.to_i; xmin = ax.min.to_i
  ymax = ay.max.to_i; ymin = ay.min.to_i
  ymin.step(ymax) do |j|
    xmin.step(xmax) do |i|
      if isinside(i, j, ax, ay) then pset(i, j, r, g, b, a) end
    end
  end
end

def isinside(x, y, ax, ay)
  (ax.length-1).times do |i|
    if oprod(ax[i+1]-ax[i],ay[i+1]-ay[i],x-ax[i],y-ay[i])<0
      return false
    end
  end
  return true
end

def oprod(a, b, c, d)
  return a*d - b*c;
end

#この下に、各自のプログラムを書くこと。レポートには、ここから下をのせること。

# 実行
#irb
#load'AI-2025.rb'
#mypict1

#convert illust.ppm illust.jpg

def triarea(w,h)
  s=(w*h)/2.0
  return s
end

def mypict1
  fillcircle(60, 90, 30, 255, 0, 0)
  fillrect(100, 60, 80, 60, 0, 255, 0) 
  writeimage("mypict1.ppm")
end

def car(u, x, y, r1, g1, b1, r2, g2, b2)
  fillcircle(x-3*u, y+2*u, 2*u, r2, g2, b2)
  fillcircle(x+3*u, y+2*u, 2*u, r2, g2, b2)
  fillrect(x, y, 6*u, 4*u, r1, g1, b1)
end

def mypict3
  car(10, 200, 150, 0, 0, 255, 255, 255, 0)
  writeimage("car1.ppm")
end

def haikei
    #緑
    #fillrect(100, 180, 200, 360, r=193, g=171, b=36, a=0.0)
    #ピンク
    fillrect(100, 180, 200, 360, r=225, g=137, b=131, a=0.0)
    #水色
    fillrect(100, 180, 200, 360, r=0, g=178, b=178, a=0.0)
    
    #writeimage("haikei.ppm")
end

def orenge(x, y)
    fillcircle(x, y, 15, r=255, g=174, b=62, a=0.0)
    filltriangle(x-5, y-12, x-7, y-7, x+2, y-5, r=78, g=167, b=46, a=0.0)
end

def orenge_all
    for i in 0..9 do
        for num in 0..5 do
            if i%2==1
                orenge(num*40, i*40)
            else
                orenge(num*40+20, i*40)
            end
        end
            writeimage("m.ppm")
    end
end
    
def cat_body
    fillrect(100, 200, 80, 140, r=47, g=72, b=88, a=0.0)
    fillellipse(80, 120, 20, 60, r=47, g=72, b=88, a=0.0)
    fillellipse(120, 120, 20, 60, r=47, g=72, b=88, a=0.0)
    fillellipse(80, 260, 20, 60, r=47, g=72, b=88, a=0.0)
    fillellipse(120, 260, 20, 60, r=47, g=72, b=88, a=0.0)
end
    
def cat_head
    fillellipse(100, 240, 50, 40, r=61, g=94, b=116, a=0.0)
    filltriangle(50, 190, 55, 230, 85, 210, r=61, g=94, b=116, a=0.0)
    filltriangle(150, 190, 145, 230, 115, 210, r=61, g=94, b=116, a=0.0)
    #はな
    fillellipse(100, 250, 8, 5, r=225, g=137, b=131, a=0.0)
    #白目
    fillrotellipse(75, 240, 15, 10, -20, r=240, g=240, b=240, a=0.0)
    fillrotellipse(125, 240, 15, 10, 20, r=240, g=240, b=240, a=0.0)
    #黒目
    fillrotellipse(78, 240, 4, 9, 0, r=0, g=178, b=178, a=0.0)
    fillrotellipse(122, 240, 4, 9, 0, r=0, g=178, b=178, a=0.0)
    #ひげ
    fillline(40, 245, 70, 255, 3, r=225, g=137, b=131, a=0.0)
    fillline(40, 270, 70, 263, 3, r=225, g=137, b=131, a=0.0)
    fillline(160, 245, 130, 255, 3, r=225, g=137, b=131, a=0.0)
    fillline(160, 270, 130, 263, 3, r=225, g=137, b=131, a=0.0)
end

def cat_tail
    fillline(100, 10, 100, 140, 10, r=61, g=94, b=116, a=0.0)
    fillcircle(100, 10, 5, r=61, g=94, b=116, a=0.0)
    fillcircle(100, 140, 5, r=61, g=94, b=116, a=0.0)
end
   
def cat_orenge
    fillcircle(100, 200, 20, r=255, g=174, b=62, a=0.0)
    filltriangle(100-5, 200-12, 100-7, 200-7, 100+2, 200-5, r=78, g=167, b=46, a=0.0)
end

def cat_stamp(x, y)
    fillrotellipse(x, y+5, 8, 6, 0, r=47, g=72, b=88, a=0.0)
    fillellipse(x-10, y-2, 4, 3, r=47, g=72, b=88, a=0.0)
    fillellipse(x-4, y-6, 4, 3, r=47, g=72, b=88, a=0.0)
    fillellipse(x+4, y-6, 4, 3, r=47, g=72, b=88, a=0.0)
    fillellipse(x+10, y-2, 4, 3, r=47, g=72, b=88, a=0.0)
end

def cat_stamp_feet(x, y)
    fillrotellipse(x, y+5, 8, 6, 0, r=225, g=137, b=131, a=0.0)
    fillellipse(x-10, y-2, 4, 3, r=225, g=137, b=131, a=0.0)
    fillellipse(x-4, y-6, 4, 3, r=225, g=137, b=131, a=0.0)
    fillellipse(x+4, y-6, 4, 3, r=225, g=137, b=131, a=0.0)
    fillellipse(x+10, y-2, 4, 3, r=225, g=137, b=131, a=0.0)
end

def cat_stamp_all
   cat_stamp(40, 40)
   cat_stamp(180, 80)
   cat_stamp(20, 160)
   cat_stamp(160, 280)
   cat_stamp(140, 0)
   cat_stamp(60, 320)
   cat_stamp(120, 360)
end

def cat_feet
   cat_stamp_feet(80, 80)
   cat_stamp_feet(120, 80)
end

def ribbon
    filltriangle(100, 25, 55, 10, 60, 35, r=0, g=178, b=178, a=0.0)
    filltriangle(100, 25, 145, 10, 140, 35, r=0, g=178, b=178, a=0.0)
    #左
    fillline(100, 25, 55, 10, 2, r=240, g=240, b=240, a=0.0)
    fillline(100, 25, 60, 35, 2, r=240, g=240, b=240, a=0.0)
    fillline(60, 35, 55, 10, 2, r=240, g=240, b=240, a=0.0)
    #右
    fillline(100, 25, 145, 10, 2, r=240, g=240, b=240, a=0.0)
    fillline(100, 25, 140, 35, 2, r=240, g=240, b=240, a=0.0)
    fillline(140, 35, 145, 10, 2, r=240, g=240, b=240, a=0.0)
end

def charactor_E
    fillline(80, 330, 120, 330, 5, r=240, g=240, b=240, a=0.0)
    fillline(80, 340, 120, 340, 5, r=240, g=240, b=240, a=0.0)
    fillline(80, 350, 120, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(80, 330, 80, 350, 5, r=240, g=240, b=240, a=0.0)
end

def charactor_M
    fillline(20, 330, 20, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(60, 330, 60, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(60, 330, 60, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(20, 330, 40, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(60, 330, 40, 350, 5, r=240, g=240, b=240, a=0.0)
end

def charactor_W
    fillline(140, 330, 140, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(140, 350, 160, 330, 5, r=240, g=240, b=240, a=0.0)
    fillline(160, 330, 180, 350, 5, r=240, g=240, b=240, a=0.0)
    fillline(180, 350, 180, 330, 5, r=240, g=240, b=240, a=0.0)
end
    
def kansei
    haikei
    orenge_all
    cat_body
    cat_tail
    ribbon
    cat_head
    cat_orenge
    cat_stamp_all
    cat_feet
    charactor_E
    charactor_M
    charactor_W
    writeimage("kansei.ppm")
end
    
    

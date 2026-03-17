import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner_model.dart';
import '../providers/banner_provider.dart';

const _dark = Color(0xFF1C1108);
const _bg   = Color(0xFFECEAE4);
const _tc   = Color(0xFFC09A60);
const _t2   = Color(0xFF6B5D4E);
const _t3   = Color(0xFFA89A8A);

TextStyle _pjs({double size=13,FontWeight weight=FontWeight.w600,Color color=_dark,double? letterSpacing,double? height})=>
    GoogleFonts.plusJakartaSans(fontSize:size,fontWeight:weight,color:color,letterSpacing:letterSpacing,height:height);

// ── BannerSection: ana sayfaya sadece bunu koy ──────────────────
class BannerSection extends ConsumerWidget {
  const BannerSection({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    return ref.watch(bannersProvider).when(
      loading:()=>const _Skeleton(),
      error:(_,__)=>const SizedBox.shrink(),
      data:(banners){
        if(banners.isEmpty) return const SizedBox.shrink();
        if(banners.length==1) return Padding(
          padding:const EdgeInsets.symmetric(horizontal:16),
          child:BannerCard(banner:banners.first));
        return _Pager(banners:banners);
      },
    );
  }
}

// ── Pager ────────────────────────────────────────────────────────
class _Pager extends StatefulWidget {
  const _Pager({required this.banners});
  final List<BannerModel> banners;
  @override State<_Pager> createState()=>_PagerState();
}
class _PagerState extends State<_Pager> {
  final _ctrl=PageController(viewportFraction:0.92);
  int _cur=0;
  @override void dispose(){_ctrl.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){
    final hasPhoto=widget.banners.any((b)=>b.imageUrl!=null&&b.imageUrl!.isNotEmpty);
    return Column(children:[
      SizedBox(
        height:hasPhoto?298:176,
        child:PageView.builder(
          controller:_ctrl,
          itemCount:widget.banners.length,
          onPageChanged:(i)=>setState(()=>_cur=i),
          itemBuilder:(_,i)=>Padding(
            padding:EdgeInsets.only(left:i==0?16:6,right:i==widget.banners.length-1?16:6),
            child:BannerCard(banner:widget.banners[i])),
        ),
      ),
      const SizedBox(height:10),
      Row(
        mainAxisAlignment:MainAxisAlignment.center,
        children:List.generate(widget.banners.length,(i){
          final on=i==_cur;
          return AnimatedContainer(
            duration:const Duration(milliseconds:240),
            margin:const EdgeInsets.symmetric(horizontal:3),
            width:on?18:6,height:6,
            decoration:BoxDecoration(
              color:on?_tc:_tc.withOpacity(0.25),
              borderRadius:BorderRadius.circular(3)),
          );
        }),
      ),
    ]);
  }
}

// ── BannerCard ───────────────────────────────────────────────────
class BannerCard extends StatefulWidget {
  const BannerCard({super.key,required this.banner,this.onTap});
  final BannerModel banner;
  final VoidCallback? onTap;
  @override State<BannerCard> createState()=>_BannerCardState();
}
class _BannerCardState extends State<BannerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override void initState(){
    super.initState();
    _ctrl=AnimationController(vsync:this,duration:const Duration(milliseconds:160));
    _scale=Tween(begin:1.0,end:0.968).animate(CurvedAnimation(parent:_ctrl,curve:Curves.easeInOut));
  }
  @override void dispose(){_ctrl.dispose();super.dispose();}

  void _tap(){
    HapticFeedback.lightImpact();
    if(widget.onTap!=null){widget.onTap!();return;}
    final url=widget.banner.linkUrl;
    if(url!=null&&url.isNotEmpty) launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context){
    final b=widget.banner;
    final isDark=b.type!=BannerType.sponsor;
    final bodyBg=isDark?_dark:_bg;
    return GestureDetector(
      onTapDown:(_)=>_ctrl.forward(),
      onTapUp:(_){_ctrl.reverse();_tap();},
      onTapCancel:()=>_ctrl.reverse(),
      child:ScaleTransition(scale:_scale,child:Container(
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(26),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.28),blurRadius:28,offset:const Offset(0,8))]),
        child:ClipRRect(borderRadius:BorderRadius.circular(26),child:Column(mainAxisSize:MainAxisSize.min,children:[
          if(b.imageUrl!=null&&b.imageUrl!.isNotEmpty) _Photo(url:b.imageUrl!,fadeTo:bodyBg),
          _Body(banner:b,isDark:isDark,bodyBg:bodyBg,onTap:_tap),
        ])),
      )),
    );
  }
}

// ── Photo ────────────────────────────────────────────────────────
class _Photo extends StatelessWidget {
  const _Photo({required this.url,required this.fadeTo});
  final String url; final Color fadeTo;
  @override
  Widget build(BuildContext context)=>SizedBox(
    width:double.infinity,height:160,
    child:Stack(fit:StackFit.expand,children:[
      CachedNetworkImage(imageUrl:url,fit:BoxFit.cover,
        fadeInDuration:const Duration(milliseconds:280),
        placeholder:(_,__)=>Container(color:_dark,child:Center(child:SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:_tc.withOpacity(0.4))))),
        errorWidget:(_,__,___)=>Container(color:_dark,child:Icon(Icons.broken_image_outlined,color:_tc.withOpacity(0.25),size:26))),
      Positioned(left:0,right:0,bottom:0,child:Container(height:90,decoration:BoxDecoration(
        gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[fadeTo,fadeTo.withOpacity(0)])))),
    ]),
  );
}

// ── Body ─────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body({required this.banner,required this.isDark,required this.bodyBg,required this.onTap});
  final BannerModel banner; final bool isDark; final Color bodyBg; final VoidCallback onTap;
  @override
  Widget build(BuildContext context){
    final b=banner;
    final textColor=isDark?Colors.white:_dark;
    final subColor=isDark?Colors.white.withOpacity(0.5):_t3;
    final metaColor=isDark?Colors.white.withOpacity(0.35):_t3;
    return Stack(children:[
      if(isDark) Positioned(right:-18,top:-18,child:Container(width:110,height:110,decoration:BoxDecoration(
        shape:BoxShape.circle,gradient:RadialGradient(colors:[_tc.withOpacity(0.18),Colors.transparent])))),
      Container(
        width:double.infinity,color:bodyBg,
        padding:const EdgeInsets.fromLTRB(18,14,18,18),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
            _TagChip(banner:b,isDark:isDark),
            Row(mainAxisSize:MainAxisSize.min,children:[
              if(b.brandName!=null&&b.brandName!.isNotEmpty) _BrandChip(name:b.brandName!,isDark:isDark),
              if(b.metaLabel!=null&&b.metaLabel!.isNotEmpty)...[
                if(b.brandName!=null) const SizedBox(width:8),
                Text(b.metaLabel!,style:_pjs(size:11,color:metaColor))],
            ]),
          ]),
          const SizedBox(height:10),
          Text(b.title,style:_pjs(size:18,weight:FontWeight.w900,color:textColor,letterSpacing:-0.4,height:1.25)),
          const SizedBox(height:4),
          Text(b.subtitle,style:_pjs(size:12,color:subColor,height:1.4)),
          const SizedBox(height:14),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,crossAxisAlignment:CrossAxisAlignment.center,children:[
            _CTA(banner:b,onTap:onTap),
            if(b.type==BannerType.sponsor) Text('Reklam',style:_pjs(size:10,color:metaColor)),
          ]),
        ]),
      ),
    ]);
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.banner,required this.isDark});
  final BannerModel banner; final bool isDark;
  @override
  Widget build(BuildContext context){
    Color bg,color; Border? border;
    switch(banner.type){
      case BannerType.kampanya: bg=_tc.withOpacity(0.2);color=_tc;border=Border.all(color:_tc.withOpacity(0.25));break;
      case BannerType.sponsor: bg=_dark.withOpacity(0.08);color=_t2;break;
      default: bg=Colors.white.withOpacity(0.09);color=Colors.white.withOpacity(0.65);
    }
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
      decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(8),border:border),
      child:Text(banner.tagLabel,style:_pjs(size:10,weight:FontWeight.w800,color:color,letterSpacing:0.05)));
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.name,required this.isDark});
  final String name; final bool isDark;
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration:BoxDecoration(color:isDark?Colors.white.withOpacity(0.1):_dark.withOpacity(0.08),borderRadius:BorderRadius.circular(8)),
    child:Text(name,style:_pjs(size:11,weight:FontWeight.w800,color:isDark?Colors.white.withOpacity(0.7):_t2)));
}

class _CTA extends StatelessWidget {
  const _CTA({required this.banner,required this.onTap});
  final BannerModel banner; final VoidCallback onTap;
  @override
  Widget build(BuildContext context){
    final isAmber=banner.type==BannerType.kampanya||(banner.type==BannerType.duyuru&&(banner.imageUrl==null||banner.imageUrl!.isEmpty));
    return GestureDetector(onTap:onTap,child:Container(
      padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),
      decoration:BoxDecoration(
        color:isAmber?_tc:_dark,borderRadius:BorderRadius.circular(12),
        boxShadow:[BoxShadow(color:isAmber?_tc.withOpacity(0.32):Colors.black.withOpacity(0.22),blurRadius:14,offset:const Offset(0,4))]),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Text(banner.ctaLabel,style:_pjs(size:13,weight:FontWeight.w800,color:Colors.white)),
        const SizedBox(width:6),
        const Icon(Icons.arrow_forward_rounded,size:14,color:Colors.white),
      ]),
    ));
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override State<_Skeleton> createState()=>_SkeletonState();
}
class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _a;
  @override void initState(){
    super.initState();
    _ctrl=AnimationController(vsync:this,duration:const Duration(milliseconds:1100))..repeat(reverse:true);
    _a=Tween(begin:0.4,end:0.85).animate(CurvedAnimation(parent:_ctrl,curve:Curves.easeInOut));
  }
  @override void dispose(){_ctrl.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.symmetric(horizontal:16),
    child:AnimatedBuilder(animation:_a,builder:(_,__)=>Container(height:176,decoration:BoxDecoration(
      color:_dark.withOpacity(_a.value*0.14),borderRadius:BorderRadius.circular(26)))));
}

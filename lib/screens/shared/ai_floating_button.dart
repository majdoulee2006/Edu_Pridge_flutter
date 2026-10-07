import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/ai_chat_screen.dart';

class AiFloatingButton extends StatefulWidget {
  final String userRole; // 'student', 'teacher', 'parent', 'boss', 'affairs'
  final String? userName;
  final double bottom;
  final double right;

  /// إن حُدد يوضع الزر على اليسار بدل اليمين (يتجاهل [right])
  final double? left;

  const AiFloatingButton({
    super.key,
    this.userRole = 'student',
    this.userName,
    this.bottom = 100,
    this.right = 20,
    this.left,
  });

  @override
  State<AiFloatingButton> createState() => _AiFloatingButtonState();
}

class _AiFloatingButtonState extends State<AiFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFCC00);

    return Positioned(
      bottom: widget.bottom,
      right: widget.left == null ? widget.right : null,
      left: widget.left,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AiChatScreen(
                  userRole: widget.userRole,
                  userName: widget.userName ?? 'المستخدم',
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 0.1);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
              ),
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryYellow,
              borderRadius: BorderRadius.circular(18), // مربع بزوايا دائرية مثل الصورة المرفقة
              boxShadow: [
                BoxShadow(
                  color: primaryYellow.withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome, // النجوم الثلاثة للذكاء الاصطناعي تماماً كالصورة
                color: Colors.black,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

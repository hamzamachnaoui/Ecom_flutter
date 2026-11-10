import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecom_app/constans.dart';
import 'package:ecom_app/providers/auth_provider.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/screens/auth/login_screen.dart';
import 'package:ecom_app/screens/auth/register_screen.dart';
import 'package:ecom_app/screens/orders/orders_screen.dart';
import 'package:ecom_app/screens/support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _referralStats;
  bool _isLoadingReferral = false;

  @override
  void initState() {
    super.initState();
    _fetchReferralStats();
  }

  void _fetchReferralStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      setState(() => _isLoadingReferral = true);
      final res = await ApiService.getReferralStats(auth.currentUser!.id);
      if (mounted) {
        setState(() {
          _isLoadingReferral = false;
          if (res['success'] == true) {
            _referralStats = res['data'];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          title: const Text('Mon Compte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 90, color: kPrimaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Connectez-vous pour débloquer toutes les fonctionnalités',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Suivi des commandes, parrainage, codes promos exclusifs et bien plus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextLightColor, fontSize: 14),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Se Connecter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryColor, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: const Text("Créer un Compte", style: TextStyle(color: kPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.support_agent_rounded, color: Colors.orange),
                  label: const Text('Contacter le Support Electro Store', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await auth.logout();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: kPrimaryColor.withOpacity(0.15),
                    child: Text(
                      user!.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: kTextLightColor, fontSize: 14)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: user.isVerified ? Colors.green.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: user.isVerified ? Colors.green : Colors.amber),
                          ),
                          child: Text(
                            user.isVerified ? '✓ Email Vérifié' : 'En attente de vérification',
                            style: TextStyle(
                              color: user.isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 18),

            // REFERRAL PROGRAM CARD (PARRAINAGE)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF023047), Color(0xFF219EBC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.card_giftcard, color: kSecondaryColor, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Programme de Parrainage',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Partagez votre code exclusif avec vos amis. Chaque ami qui s\'inscrit vous fait gagner 25 DH de réduction !',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Votre code parrain :', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text(
                              user.referralCode,
                              style: const TextStyle(
                                color: kSecondaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSecondaryColor,
                            foregroundColor: kTextColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text('Code parrain copié dans le presse-papiers !'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copier', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Referral Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _isLoadingReferral
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      '${_referralStats?['referrals_count'] ?? 0}',
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                              const Text('Filleuls inscrits', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_referralStats?['total_earnings'] ?? 0} DH',
                                style: const TextStyle(color: kSecondaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text('Gains cumulés', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Order History Shortcut
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: kPrimaryColor),
                title: const Text('Historique de mes Commandes', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Suivez l\'état de vos achats'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
              ),
            ),

            const SizedBox(height: 12),

            // Support Client / SAV Shortcut
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.support_agent_rounded, color: Colors.orange),
                title: const Text('Support Client, Pannes & SAV', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Contactez Electro Store ou signalez une panne'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                },
              ),
            ),

            const SizedBox(height: 12),

            // Available coupons guide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_offer_outlined, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text('Coupons disponibles pour vous :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _couponItem('BIENVENUE10', '10% de réduction immédiate dès 50 DH'),
                  _couponItem('SOLDES20', '20% de remise sur tout le catalogue dès 100 DH'),
                  _couponItem('PROMO50', '50 DH offerts dès 200 DH d\'achat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _couponItem(String code, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kSecondaryColor),
            ),
            child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextColor)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: kTextLightColor))),
        ],
      ),
    );
  }
}

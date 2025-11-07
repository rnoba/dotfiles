from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.units import cm

file_path_left = "./test.pdf"

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='Header', fontSize=16, leading=20, spaceAfter=6, textColor=colors.HexColor("#333333"), alignment=0))
styles.add(ParagraphStyle(name='SubHeader', fontSize=11, leading=16, spaceAfter=2, textColor=colors.HexColor("#555555"), alignment=0))
styles.add(ParagraphStyle(name='SectionTitle', fontSize=12, leading=14, spaceBefore=10, spaceAfter=6, textColor=colors.HexColor("#000000"), underlineWidth=0.5))
styles.add(ParagraphStyle(name='NormalText', fontSize=10.5, leading=14, textColor=colors.HexColor("#333333")))

doc = SimpleDocTemplate(file_path_left, pagesize=A4, leftMargin=2.2*cm, rightMargin=2.2*cm, topMargin=1.8*cm, bottomMargin=1.8*cm)
elements = []

elements.append(Paragraph("<b>Rafael Nogueira Barros</b>", styles['Header']))
elements.append(Paragraph("📍 Ferraz de Vasconcelos – SP | Brasileiro | 23 anos | Solteiro", styles['SubHeader']))
elements.append(Paragraph("📧 rnoba.iwb@gmail.com | 📱 (11) 96392-1941", styles['SubHeader']))
elements.append(Paragraph('Github: <link href="https://github.com/rnoba" color="blue">https://github.com/rnoba</link>', styles['SubHeader']))
elements.append(Spacer(1, 12))

elements.append(Paragraph("Resumo Profissional", styles['SectionTitle']))
elements.append(Paragraph(
    "Desenvolvedor <b>Full Stack Web e Mobile</b>, com experiência em <b>Node.js, C#, Dart, React Native, TypeScript, Java e Spring Boot</b>. "
    "Perfil analítico, proativo e orientado a resultados, com foco em desenvolvimento limpo, escalável e de alta performance. "
    "Forte base em lógica, algoritmos e arquitetura de software, adquirida em ambientes colaborativos e de aprendizado intensivo como a <b>42 São Paulo</b>.", 
    styles['NormalText']))
elements.append(Spacer(1, 8))

elements.append(Paragraph("Experiência Profissional", styles['SectionTitle']))

elements.append(Paragraph("<b>Ace4 – Desenvolvedor Full Stack (Freelancer)</b>", styles['NormalText']))
elements.append(Paragraph("Jan/2025 – Mai/2025 | Remoto", styles['NormalText']))
elements.append(Paragraph(
    "- Desenvolvimento de aplicações web utilizando <b>C# (ASP.NET)</b> e <b>JavaScript</b>.<br/>"
    "- Implementação de APIs REST, autenticação e integração com bancos de dados relacionais.<br/>"
    "- Criação de interfaces dinâmicas e componentes reutilizáveis.<br/>"
    "- Colaboração com equipe de design e backend para entrega de produtos escaláveis.<br/>"
    "<b>Tecnologias:</b> C#, .NET, JavaScript, HTML, CSS, SQL Server, Git.", styles['NormalText']))
elements.append(Spacer(1, 6))

elements.append(Paragraph("<b>Freelancer – Desenvolvimento de Bot para Discord</b>", styles['NormalText']))
elements.append(Paragraph("Dez/2022 – Fev/2023 | Remoto", styles['NormalText']))
elements.append(Paragraph(
    "- Criação de bot personalizado em <b>TypeScript</b>, com sistema de comandos dinâmicos e eventos automatizados.<br/>"
    "- Integração com APIs externas e armazenamento de dados com <b>MongoDB</b>.<br/>"
    "- Deploy em ambiente de produção com logs e monitoramento contínuo.<br/>"
    "<b>Tecnologias:</b> Node.js, TypeScript, Discord.js, MongoDB.", styles['NormalText']))
elements.append(Spacer(1, 8))

elements.append(Paragraph("Formação Acadêmica", styles['SectionTitle']))
elements.append(Paragraph("<b>Tecnólogo em Análise e Desenvolvimento de Sistemas</b><br/>Universidade Braz Cubas – Incompleto (último semestre)", styles['NormalText']))
elements.append(Spacer(1, 4))
elements.append(Paragraph("<b>Ex-Cadete – 42 São Paulo</b><br/>Escola internacional de programação baseada em projetos e aprendizado autodirigido (peer-to-peer). "
                          "Foco em algoritmos, estruturas de dados, C, Shell Script, Git, redes e segurança. "
                          "Desenvolvimento de projetos colaborativos com ênfase em lógica, autonomia e boas práticas.", styles['NormalText']))
elements.append(Spacer(1, 8))

elements.append(Paragraph("Conhecimentos Técnicos", styles['SectionTitle']))
elements.append(Paragraph(
    "<b>Linguagens & Frameworks:</b> C#, JavaScript, TypeScript, Python, React, Node.js, Svelte, Dart, Java, Rust, C<br/>"
    "<b>Banco de Dados:</b> MySQL, PostgreSQL, MongoDB, SQL Server<br/>"
    "<b>Front-end:</b> HTML, CSS, TailwindCSS, Bootstrap<br/>"
    "<b>Infra & DevOps:</b> Docker, Git, CI/CD básico<br/>"
    "<b>Arquitetura & Boas Práticas:</b> REST API, MVC, Clean Code, SOLID", styles['NormalText']))
elements.append(Spacer(1, 8))

elements.append(Paragraph("Idiomas", styles['SectionTitle']))
elements.append(Paragraph("<b>Português:</b> Nativo<br/><b>Inglês:</b> Avançado (leitura, escrita e conversação)", styles['NormalText']))

doc.build(elements)

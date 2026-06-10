import streamlit as st
import requests
import base64

# ยิงไปหา API Container ที่อยู่ในวง Docker Network เดียวกัน
API_URL = "http://api:8000/api/v1/chat"

# ปรับ Layout เป็นแบบ wide เพื่อให้มีพื้นที่กาง PDF และแชทได้เต็มที่
st.set_page_config(page_title="AI HR Agent", page_icon="👔", layout="wide")

st.title("👔 AI HR Agent - Resume Analyzer")
st.markdown("อัปโหลดไฟล์ PDF ของเรซูเม่ และพิมพ์คำสั่งให้ AI ช่วยวิเคราะห์ได้เลยครับ!")

# แบ่งหน้าจอเป็น 2 ฝั่ง ซ้าย(1) : ขวา(1)
col_left, col_right = st.columns([1, 1])

with col_left:
    st.subheader("📄 ต้นฉบับ Resume")
    uploaded_file = st.file_uploader("📂 อัปโหลดไฟล์ Resume (PDF)", type=["pdf"])
    
    # ถ้าอัปโหลดไฟล์แล้ว ให้แสดง PDF
    if uploaded_file is not None:
        # อ่านไฟล์และแปลงเป็น Base64 เพื่อให้บราวเซอร์แสดงผลได้
        base64_pdf = base64.b64encode(uploaded_file.getvalue()).decode('utf-8')
        # สร้าง HTML iframe สำหรับโชว์ PDF (ตั้งความสูงไว้ที่ 800px)
        pdf_display = f'<iframe src="data:application/pdf;base64,{base64_pdf}" width="100%" height="800" type="application/pdf"></iframe>'
        st.markdown(pdf_display, unsafe_allow_html=True)
    else:
        st.info("💡 กรุณาอัปโหลดไฟล์ PDF เพื่อดูตัวอย่างเอกสารที่นี่")

with col_right:
    st.subheader("🤖 AI วิเคราะห์")
    prompt = st.text_area("💬 ข้อความคำสั่ง (Prompt)", value="วิเคราะห์เรซูเม่ หาตำแหน่งงานที่เหมาะสม และสรุปสิ่งที่ควรพัฒนาให้ฟังหน่อย", height=100)
    
    if st.button("ส่งให้ AI วิเคราะห์ 🚀", use_container_width=True):
        if uploaded_file is not None and prompt:
            with st.spinner("🧠 AI กำลังทำงาน... (อาจใช้เวลาสักครู่)"):
                files = {"file": (uploaded_file.name, uploaded_file.getvalue(), "application/pdf")}
                data = {"prompt": prompt}
                try:
                    response = requests.post(API_URL, files=files, data=data)
                    if response.status_code == 200:
                        result = response.json()
                        st.success("✅ วิเคราะห์สำเร็จ!")
                        st.markdown("### 📊 ผลการวิเคราะห์")
                        
                        # ใช้ช่องข้อความแบบยาวเพื่อให้ตัวหนังสืออ่านง่าย
                        st.info(result.get("answer", "ไม่มีคำตอบจาก AI"))
                    else:
                        st.error(f"❌ เกิดข้อผิดพลาดจาก API (Status {response.status_code})")
                        st.write(response.text)
                except Exception as e:
                    st.error(f"❌ ไม่สามารถเชื่อมต่อกับ API ได้: {e}")
        else:
            st.warning("⚠️ กรุณาอัปโหลดไฟล์และกรอกข้อความคำสั่งก่อนครับ")
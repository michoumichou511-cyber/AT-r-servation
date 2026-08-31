import { useNavigate } from 'react-router-dom'

export default function Page404() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#F8FAFB] dark:bg-[#0A0F1E] gap-5 p-6 relative overflow-hidden">
      <div className="absolute w-[300px] h-[300px] rounded-full bg-[#00A650]/[0.04] dark:bg-[#00A650]/[0.08] top-[10%] right-[-5%]" />
      <div className="absolute w-[200px] h-[200px] rounded-full bg-[#003DA5]/[0.04] dark:bg-[#003DA5]/[0.08] bottom-[15%] left-[-3%]" />
      <div className="text-[140px] font-black text-[#003DA5] leading-none tracking-tighter relative z-[1]">
        404
      </div>
      <h2 className="text-2xl font-extrabold text-[#1A1D26] dark:text-[#E8EAF0] m-0 relative z-[1]">
        Page introuvable
      </h2>
      <p className="text-[#5A6070] dark:text-[#9AA0AE] text-[15px] text-center max-w-[340px] leading-relaxed relative z-[1]">
        La page que vous cherchez n&apos;existe pas ou a été déplacée.
      </p>
      <button
        type="button"
        onClick={() => navigate('/')}
        className="at-btn-gradient relative z-[1] mt-1"
      >
        Retour à l&apos;accueil
      </button>
    </div>
  )
}

"use client";
import { useState } from "react";
import { supabase } from "@/lib/supabase";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
  const router = useRouter();
  const [nickname, setNickname] = useState("");
  const [instagramId, setInstagramId] = useState("");
  const [bio, setBio] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setPreview(URL.createObjectURL(f));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!file || !nickname || !instagramId) return;
    setLoading(true);

    // 1. 익명 로그인
    const { data: auth } = await supabase.auth.signInAnonymously();
    const userId = auth.user?.id;
    if (!userId) return;

    // 2. 사진 업로드
    const ext = file.name.split(".").pop();
    const path = `${userId}.${ext}`;
    await supabase.storage.from("pet-photos").upload(path, file, { upsert: true });
    const { data: urlData } = supabase.storage.from("pet-photos").getPublicUrl(path);

    // 3. 프로필 저장
    await supabase.from("users").upsert({
      id: userId,
      nickname,
      instagram_id: instagramId,
      bio,
      pet_photo_url: urlData.publicUrl,
    });

    router.push("/");
  }

  return (
    <main className="min-h-dvh bg-[#fdf6f0] flex items-center justify-center px-4">
      <div className="w-full max-w-sm bg-white rounded-3xl shadow-xl p-8">
        <h1 className="text-2xl font-black text-purple-600 mb-1">🐾 Pet & Met</h1>
        <p className="text-gray-400 text-sm mb-6">동물 사진으로 시작해요</p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {/* 사진 업로드 */}
          <label className="cursor-pointer">
            <div className="w-full h-48 rounded-2xl bg-gray-100 flex items-center justify-center overflow-hidden border-2 border-dashed border-gray-200 hover:border-purple-300 transition-colors">
              {preview
                ? <img src={preview} className="w-full h-full object-cover" alt="preview" />
                : <span className="text-gray-400 text-sm">🐶 동물 사진 업로드</span>
              }
            </div>
            <input type="file" accept="image/*" className="hidden" onChange={handleFileChange} />
          </label>

          <input
            type="text" placeholder="닉네임" value={nickname}
            onChange={e => setNickname(e.target.value)}
            className="border border-gray-200 rounded-2xl px-4 py-3 text-sm outline-none focus:border-purple-400"
            required
          />
          <input
            type="text" placeholder="인스타그램 ID (@없이)" value={instagramId}
            onChange={e => setInstagramId(e.target.value)}
            className="border border-gray-200 rounded-2xl px-4 py-3 text-sm outline-none focus:border-purple-400"
            required
          />
          <textarea
            placeholder="한 줄 소개 (선택)" value={bio}
            onChange={e => setBio(e.target.value)}
            rows={2}
            className="border border-gray-200 rounded-2xl px-4 py-3 text-sm outline-none focus:border-purple-400 resize-none"
          />

          <button
            type="submit" disabled={loading}
            className="bg-gradient-to-r from-purple-500 to-pink-500 text-white font-bold py-4 rounded-2xl disabled:opacity-50"
          >
            {loading ? "등록 중..." : "시작하기 🐾"}
          </button>
        </form>
      </div>
    </main>
  );
}

 

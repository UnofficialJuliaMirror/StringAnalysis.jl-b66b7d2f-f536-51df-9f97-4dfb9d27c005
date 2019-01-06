@testset "LSA" begin
    # Documents
    doc1 = StringDocument("This is a text about an apple. There are many texts about apples.")
    doc2 = StringDocument("Pears and apples are good but not exotic. An apple a day keeps the doctor away.")
    doc3 = StringDocument("Fruits are good for you.")
    doc4 = StringDocument("This phrase has nothing to do with the others...")
    doc5 = StringDocument("Simple text, little info inside")
    # Corpus
    crps = Corpus(AbstractDocument[doc1, doc2, doc3, doc4, doc5])
    prepare!(crps, strip_punctuation)
    update_lexicon!(crps)
    update_inverse_index!(crps)
    lex = sort(collect(keys(crps.lexicon)))
    # Retrieval
    query = StringDocument("Apples and an exotic fruit.")
    for k in [1, 3]
        for stats in [:tf, :tfidf, :bm25]
            for T in [Float32, Float64]
                dtm = DocumentTermMatrix{T}(crps, lex)
                model = lsa(dtm, k=k, stats=stats)
                @test model isa LSAModel{String, T, SparseMatrixCSC{T,Int}, Int}
                idxs, corrs = cosine(model, query)
                @test length(idxs) == length(corrs) == length(crps)
                @test size(model.Σinv, 1) == k
            end
        end
    end
    # Tests for the rest of the functions
    K = 2
    T = Float32
    model = lsa(crps, k=K)
    @test model isa LSAModel{String, T, SparseMatrixCSC{T, Int}, Int}
    @test all(StringAnalysis.in_vocabulary(model, word) for word in keys(crps.lexicon))
    @test StringAnalysis.vocabulary(model) == sort(collect(keys(crps.lexicon)))
    @test size(model) == (length(crps.lexicon), length(crps), K)
    idx = 2
    word = model.vocab[idx]
    @test index(model, word) == model.vocab_hash[word]
    @test get_vector(model, word) == model.Vᵀ[:, idx]
    @test similarity(model, crps[1], crps[2]) isa T
    @test similarity(model, crps[1], crps[2]) == similarity(model, crps[2], crps[1])
    @test_throws ErrorException LSAModel(DocumentTermMatrix{Int}(crps), k=K)
    @test_throws ErrorException embed_word(model, "word")
end


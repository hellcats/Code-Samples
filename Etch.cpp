//... Lots of code remove here

#if CODEGEN_PREFIX
	<%
	using System;
	using System.Collections;
	using System.Xml;

	namespace CodeGen
	{
		public class Ref
		{
			public string Cell;
			public int Atom;

			public Ref(string cell, int atom)
			{
				Cell = cell;
				Atom = atom;
			}
		}

		public class MainClass
		{
		  public
			Ref Neighbor(int atom, int i)
			{
				Ref[] arr = null;
				switch (atom)
				{
				case 0:
					arr = new Ref[]{
						new Ref("S", 6), new Ref("E", 7), new Ref("D", 4), new Ref("SED", 5)};
					break;

				case 1:
					arr = new Ref[]{
						new Ref("cell", 4), new Ref("cell", 6), new Ref("E", 7), new Ref("E", 5)};
					break;

				case 2:
					arr = new Ref[]{
						new Ref("cell", 7), new Ref("cell", 4), new Ref("S", 5), new Ref("S", 6)};
					break;

				case 3:
					arr = new Ref[]{
						new Ref("cell", 6), new Ref("cell", 7), new Ref("D", 4), new Ref("D", 5)};
					break;

				case 4:
					arr = new Ref[]{
						new Ref("cell", 1), new Ref("cell", 2), new Ref("U", 0), new Ref("U", 3)};
					break;

				case 5:
					arr = new Ref[]{
						new Ref("N", 2), new Ref("W", 1), new Ref("U", 3), new Ref("NWU", 0)};
					break;

				case 6:
					arr = new Ref[]{
						new Ref("cell", 1), new Ref("cell", 3), new Ref("N", 0), new Ref("N", 2)};
					break;

				case 7:
					arr = new Ref[]{
						new Ref("cell", 2), new Ref("cell", 3), new Ref("W", 0), new Ref("W", 1)};
					break;
				}
				return arr[i];
			}

		  public
			Hashtable Names()
			{
				Hashtable ht = new Hashtable();

				for (int x = -1; x <= 1; x++)
					for (int y = -1; y <= 1; y++)
						for (int z = -1; z <= 1; z++)
						{
							string cell = "";
							if (x == -1)
								cell += "S";
							else if (x == 1)
								cell += "N";
							if (y == -1)
								cell += "E";
							else if (y == 1)
								cell += "W";
							if (z == -1)
								cell += "D";
							else if (z == 1)
								cell += "U";
							if (cell == "")
								cell = "cell";
							ht[cell] = new int[]{
								x, y, z};
						}
				return ht;
			}

		  public
			Ref DoubleRef(Ref r1, Ref r2)
			{
				Hashtable ht = Names();

				int[] d1 = (int[])ht[r1.Cell];
				int[] d2 = (int[])ht[r2.Cell];
				int[] d = new int[3];
				for (int i = 0; i < 3; i++)
					d[i] = d1[i] + d2[i];

				foreach (string key in ht.Keys)
				{
					int[] val = (int[])ht[key];
					bool found = true;
					for (int i = 0; i < 3; i++)
						if (val[i] != d[i])
						{
							found = false;
							break;
						}
					if (found)
						return new Ref(key, r2.Atom);
				}

				return null;
			}

			public void NeighborCounts(string func1, string func2, string mode)
			{
				%> switch (atom)
				{
					<% for (int a = 0; a < 8; a++)
					{
						%> case <%=a%>:
								{
								<%					// Declare required Cells
								Hashtable names = Names();
								Hashtable ht = new Hashtable();
								for (int i = 0; i < 4; i++)
								{
									Ref r1 = Neighbor(a, i);
									ht[r1.Cell] = 1;
									for (int j = 0; j < 4; j++)
									{
										Ref r2 = Neighbor(r1.Atom, j);
										Ref r = DoubleRef(r1, r2);
										ht[r.Cell] = 1;
									}
								}
								foreach (string key in ht.Keys)
								{
									int[] d = (int[])names[key];
									if (key != "cell")
										%> MCCell& <%=key%> = *findCell(x+<%=d[0]%>, y+<%=d[1]%>, z+<%=d[2]%>, <%=mode%>);
									<% }

								// Call neighbor functions.
								for (int i = 0; i < 4; i++)
								{
									Ref r1 = Neighbor(a, i);
									%> <%=func1%>(cell, atom, <%=r1.Cell%>, <%=r1.Atom%>);
									<% for (int j = 0; j < 4; j++)
									{
										Ref r2 = Neighbor(r1.Atom, j);
										Ref r = DoubleRef(r1, r2);
										if (r.Atom == a)		// Don't decrement myself
											continue;
										%> <%=func2%>(cell, atom, <%=r.Cell%>, <%=r.Atom%>);
										<% }
								}
								%> break;
							}
							<% }
					%> }
				<% }

			public static void Main()
			{
				MainClass obj = new MainClass();
				obj.Run();
			}


			public void Run()
			{
				%>
#endif

				// North/South	= +/- X
				// West/East	= +/- Y
				// Up/Down		= +/- Z

				void CMCAnisotropic::countNeighbors(MCCell* p, Int32 mode)
				{
					MCCell& cell = *p;
					Uint32 x = p->x;
					Uint32 y = p->y;
					Uint32 z = p->z;

					p->counted = 1;
					for (Int32 atom = 0; atom < 8; atom++)
					{
						cell.mcAtoms[atom].cnt1 = 0;
						cell.mcAtoms[atom].cnt2 = 0;

#if CODEGEN
						<% NeighborCounts("initCnt1", "initCnt2", "mode");
						%>
#else

						switch (atom)
						{
							case 0:
							{
								MCCell& ED = *findCell(x+0, y+-1, z+-1, mode);
								MCCell& SED = *findCell(x+-1, y+-1, z+-1, mode);
								MCCell& SE = *findCell(x+-1, y+-1, z+0, mode);
								MCCell& SD = *findCell(x+-1, y+0, z+-1, mode);
								MCCell& D = *findCell(x+0, y+0, z+-1, mode);
								MCCell& E = *findCell(x+0, y+-1, z+0, mode);
								MCCell& S = *findCell(x+-1, y+0, z+0, mode);
								initCnt1(cell, atom, S, 6);
								initCnt2(cell, atom, S, 1);
								initCnt2(cell, atom, S, 3);
								initCnt2(cell, atom, cell, 2);
								initCnt1(cell, atom, E, 7);
								initCnt2(cell, atom, E, 2);
								initCnt2(cell, atom, E, 3);
								initCnt2(cell, atom, cell, 1);
								initCnt1(cell, atom, D, 4);
								initCnt2(cell, atom, D, 1);
								initCnt2(cell, atom, D, 2);
								initCnt2(cell, atom, cell, 3);
								initCnt1(cell, atom, SED, 5);
								initCnt2(cell, atom, ED, 2);
								initCnt2(cell, atom, SD, 1);
								initCnt2(cell, atom, SE, 3);
								break;
							}
							case 1:
							{
								MCCell& NU = *findCell(x+1, y+0, z+1, mode);
								MCCell& U = *findCell(x+0, y+0, z+1, mode);
								MCCell& E = *findCell(x+0, y+-1, z+0, mode);
								MCCell& NE = *findCell(x+1, y+-1, z+0, mode);
								MCCell& N = *findCell(x+1, y+0, z+0, mode);
								MCCell& EU = *findCell(x+0, y+-1, z+1, mode);
								initCnt1(cell, atom, cell, 4);
								initCnt2(cell, atom, cell, 2);
								initCnt2(cell, atom, U, 0);
								initCnt2(cell, atom, U, 3);
								initCnt1(cell, atom, cell, 6);
								initCnt2(cell, atom, cell, 3);
								initCnt2(cell, atom, N, 0);
								initCnt2(cell, atom, N, 2);
								initCnt1(cell, atom, E, 7);
								initCnt2(cell, atom, E, 2);
								initCnt2(cell, atom, E, 3);
								initCnt2(cell, atom, cell, 0);
								initCnt1(cell, atom, E, 5);
								initCnt2(cell, atom, NE, 2);
								initCnt2(cell, atom, EU, 3);
								initCnt2(cell, atom, NU, 0);
								break;
							}
							case 2:
							{
								MCCell& W = *findCell(x+0, y+1, z+0, mode);
								MCCell& SU = *findCell(x+-1, y+0, z+1, mode);
								MCCell& SW = *findCell(x+-1, y+1, z+0, mode);
								MCCell& WU = *findCell(x+0, y+1, z+1, mode);
								MCCell& U = *findCell(x+0, y+0, z+1, mode);
								MCCell& S = *findCell(x+-1, y+0, z+0, mode);
								initCnt1(cell, atom, cell, 7);
								initCnt2(cell, atom, cell, 3);
								initCnt2(cell, atom, W, 0);
								initCnt2(cell, atom, W, 1);
								initCnt1(cell, atom, cell, 4);
								initCnt2(cell, atom, cell, 1);
								initCnt2(cell, atom, U, 0);
								initCnt2(cell, atom, U, 3);
								initCnt1(cell, atom, S, 5);
								initCnt2(cell, atom, SW, 1);
								initCnt2(cell, atom, SU, 3);
								initCnt2(cell, atom, WU, 0);
								initCnt1(cell, atom, S, 6);
								initCnt2(cell, atom, S, 1);
								initCnt2(cell, atom, S, 3);
								initCnt2(cell, atom, cell, 0);
								break;
							}
							case 3:
							{
								MCCell& NW = *findCell(x+1, y+1, z+0, mode);
								MCCell& ND = *findCell(x+1, y+0, z+-1, mode);
								MCCell& D = *findCell(x+0, y+0, z+-1, mode);
								MCCell& N = *findCell(x+1, y+0, z+0, mode);
								MCCell& WD = *findCell(x+0, y+1, z+-1, mode);
								MCCell& W = *findCell(x+0, y+1, z+0, mode);
								initCnt1(cell, atom, cell, 6);
								initCnt2(cell, atom, cell, 1);
								initCnt2(cell, atom, N, 0);
								initCnt2(cell, atom, N, 2);
								initCnt1(cell, atom, cell, 7);
								initCnt2(cell, atom, cell, 2);
								initCnt2(cell, atom, W, 0);
								initCnt2(cell, atom, W, 1);
								initCnt1(cell, atom, D, 4);
								initCnt2(cell, atom, D, 1);
								initCnt2(cell, atom, D, 2);
								initCnt2(cell, atom, cell, 0);
								initCnt1(cell, atom, D, 5);
								initCnt2(cell, atom, ND, 2);
								initCnt2(cell, atom, WD, 1);
								initCnt2(cell, atom, NW, 0);
								break;
							}
							case 4:
							{
								MCCell& SU = *findCell(x+-1, y+0, z+1, mode);
								MCCell& SE = *findCell(x+-1, y+-1, z+0, mode);
								MCCell& EU = *findCell(x+0, y+-1, z+1, mode);
								MCCell& U = *findCell(x+0, y+0, z+1, mode);
								MCCell& E = *findCell(x+0, y+-1, z+0, mode);
								MCCell& S = *findCell(x+-1, y+0, z+0, mode);
								initCnt1(cell, atom, cell, 1);
								initCnt2(cell, atom, cell, 6);
								initCnt2(cell, atom, E, 7);
								initCnt2(cell, atom, E, 5);
								initCnt1(cell, atom, cell, 2);
								initCnt2(cell, atom, cell, 7);
								initCnt2(cell, atom, S, 5);
								initCnt2(cell, atom, S, 6);
								initCnt1(cell, atom, U, 0);
								initCnt2(cell, atom, SU, 6);
								initCnt2(cell, atom, EU, 7);
								initCnt2(cell, atom, SE, 5);
								initCnt1(cell, atom, U, 3);
								initCnt2(cell, atom, U, 6);
								initCnt2(cell, atom, U, 7);
								initCnt2(cell, atom, cell, 5);
								break;
							}
							case 5:
							{
								MCCell& W = *findCell(x+0, y+1, z+0, mode);
								MCCell& U = *findCell(x+0, y+0, z+1, mode);
								MCCell& N = *findCell(x+1, y+0, z+0, mode);
								MCCell& WU = *findCell(x+0, y+1, z+1, mode);
								MCCell& NWU = *findCell(x+1, y+1, z+1, mode);
								MCCell& NU = *findCell(x+1, y+0, z+1, mode);
								MCCell& NW = *findCell(x+1, y+1, z+0, mode);
								initCnt1(cell, atom, N, 2);
								initCnt2(cell, atom, N, 7);
								initCnt2(cell, atom, N, 4);
								initCnt2(cell, atom, cell, 6);
								initCnt1(cell, atom, W, 1);
								initCnt2(cell, atom, W, 4);
								initCnt2(cell, atom, W, 6);
								initCnt2(cell, atom, cell, 7);
								initCnt1(cell, atom, U, 3);
								initCnt2(cell, atom, U, 6);
								initCnt2(cell, atom, U, 7);
								initCnt2(cell, atom, cell, 4);
								initCnt1(cell, atom, NWU, 0);
								initCnt2(cell, atom, WU, 6);
								initCnt2(cell, atom, NU, 7);
								initCnt2(cell, atom, NW, 4);
								break;
							}
							case 6:
							{
								MCCell& ED = *findCell(x+0, y+-1, z+-1, mode);
								MCCell& N = *findCell(x+1, y+0, z+0, mode);
								MCCell& ND = *findCell(x+1, y+0, z+-1, mode);
								MCCell& NE = *findCell(x+1, y+-1, z+0, mode);
								MCCell& D = *findCell(x+0, y+0, z+-1, mode);
								MCCell& E = *findCell(x+0, y+-1, z+0, mode);
								initCnt1(cell, atom, cell, 1);
								initCnt2(cell, atom, cell, 4);
								initCnt2(cell, atom, E, 7);
								initCnt2(cell, atom, E, 5);
								initCnt1(cell, atom, cell, 3);
								initCnt2(cell, atom, cell, 7);
								initCnt2(cell, atom, D, 4);
								initCnt2(cell, atom, D, 5);
								initCnt1(cell, atom, N, 0);
								initCnt2(cell, atom, NE, 7);
								initCnt2(cell, atom, ND, 4);
								initCnt2(cell, atom, ED, 5);
								initCnt1(cell, atom, N, 2);
								initCnt2(cell, atom, N, 7);
								initCnt2(cell, atom, N, 4);
								initCnt2(cell, atom, cell, 5);
								break;
							}
							case 7:
							{
								MCCell& W = *findCell(x+0, y+1, z+0, mode);
								MCCell& S = *findCell(x+-1, y+0, z+0, mode);
								MCCell& SW = *findCell(x+-1, y+1, z+0, mode);
								MCCell& SD = *findCell(x+-1, y+0, z+-1, mode);
								MCCell& D = *findCell(x+0, y+0, z+-1, mode);
								MCCell& WD = *findCell(x+0, y+1, z+-1, mode);
								initCnt1(cell, atom, cell, 2);
								initCnt2(cell, atom, cell, 4);
								initCnt2(cell, atom, S, 5);
								initCnt2(cell, atom, S, 6);
								initCnt1(cell, atom, cell, 3);
								initCnt2(cell, atom, cell, 6);
								initCnt2(cell, atom, D, 4);
								initCnt2(cell, atom, D, 5);
								initCnt1(cell, atom, W, 0);
								initCnt2(cell, atom, SW, 6);
								initCnt2(cell, atom, WD, 4);
								initCnt2(cell, atom, SD, 5);
								initCnt1(cell, atom, W, 1);
								initCnt2(cell, atom, W, 4);
								initCnt2(cell, atom, W, 6);
								initCnt2(cell, atom, cell, 5);
								break;
							}
						}


#endif
					}
				}

				void CMCAnisotropic::countNeighbors(Uint32 x, Uint32 y, Uint32 z, Int32 atom)
				{
					MCCell& cell = *m_celltable.findSimple(x, y, z);

					cell.mcAtoms[atom].cnt1 = 0;
					cell.mcAtoms[atom].cnt2 = 0;


#if CODEGEN
					<% NeighborCounts("initCnt1", "initCnt2", "2");
					%>
#else

					switch (atom)
					{
						case 0:
						{
							MCCell& ED = *findCell(x+0, y+-1, z+-1, 2);
							MCCell& SED = *findCell(x+-1, y+-1, z+-1, 2);
							MCCell& SE = *findCell(x+-1, y+-1, z+0, 2);
							MCCell& SD = *findCell(x+-1, y+0, z+-1, 2);
							MCCell& D = *findCell(x+0, y+0, z+-1, 2);
							MCCell& E = *findCell(x+0, y+-1, z+0, 2);
							MCCell& S = *findCell(x+-1, y+0, z+0, 2);
							initCnt1(cell, atom, S, 6);
							initCnt2(cell, atom, S, 1);
							initCnt2(cell, atom, S, 3);
							initCnt2(cell, atom, cell, 2);
							initCnt1(cell, atom, E, 7);
							initCnt2(cell, atom, E, 2);
							initCnt2(cell, atom, E, 3);
							initCnt2(cell, atom, cell, 1);
							initCnt1(cell, atom, D, 4);
							initCnt2(cell, atom, D, 1);
							initCnt2(cell, atom, D, 2);
							initCnt2(cell, atom, cell, 3);
							initCnt1(cell, atom, SED, 5);
							initCnt2(cell, atom, ED, 2);
							initCnt2(cell, atom, SD, 1);
							initCnt2(cell, atom, SE, 3);
							break;
						}
						case 1:
						{
							MCCell& NU = *findCell(x+1, y+0, z+1, 2);
							MCCell& U = *findCell(x+0, y+0, z+1, 2);
							MCCell& E = *findCell(x+0, y+-1, z+0, 2);
							MCCell& NE = *findCell(x+1, y+-1, z+0, 2);
							MCCell& N = *findCell(x+1, y+0, z+0, 2);
							MCCell& EU = *findCell(x+0, y+-1, z+1, 2);
							initCnt1(cell, atom, cell, 4);
							initCnt2(cell, atom, cell, 2);
							initCnt2(cell, atom, U, 0);
							initCnt2(cell, atom, U, 3);
							initCnt1(cell, atom, cell, 6);
							initCnt2(cell, atom, cell, 3);
							initCnt2(cell, atom, N, 0);
							initCnt2(cell, atom, N, 2);
							initCnt1(cell, atom, E, 7);
							initCnt2(cell, atom, E, 2);
							initCnt2(cell, atom, E, 3);
							initCnt2(cell, atom, cell, 0);
							initCnt1(cell, atom, E, 5);
							initCnt2(cell, atom, NE, 2);
							initCnt2(cell, atom, EU, 3);
							initCnt2(cell, atom, NU, 0);
							break;
						}
						case 2:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 2);
							MCCell& SU = *findCell(x+-1, y+0, z+1, 2);
							MCCell& SW = *findCell(x+-1, y+1, z+0, 2);
							MCCell& WU = *findCell(x+0, y+1, z+1, 2);
							MCCell& U = *findCell(x+0, y+0, z+1, 2);
							MCCell& S = *findCell(x+-1, y+0, z+0, 2);
							initCnt1(cell, atom, cell, 7);
							initCnt2(cell, atom, cell, 3);
							initCnt2(cell, atom, W, 0);
							initCnt2(cell, atom, W, 1);
							initCnt1(cell, atom, cell, 4);
							initCnt2(cell, atom, cell, 1);
							initCnt2(cell, atom, U, 0);
							initCnt2(cell, atom, U, 3);
							initCnt1(cell, atom, S, 5);
							initCnt2(cell, atom, SW, 1);
							initCnt2(cell, atom, SU, 3);
							initCnt2(cell, atom, WU, 0);
							initCnt1(cell, atom, S, 6);
							initCnt2(cell, atom, S, 1);
							initCnt2(cell, atom, S, 3);
							initCnt2(cell, atom, cell, 0);
							break;
						}
						case 3:
						{
							MCCell& NW = *findCell(x+1, y+1, z+0, 2);
							MCCell& ND = *findCell(x+1, y+0, z+-1, 2);
							MCCell& D = *findCell(x+0, y+0, z+-1, 2);
							MCCell& N = *findCell(x+1, y+0, z+0, 2);
							MCCell& WD = *findCell(x+0, y+1, z+-1, 2);
							MCCell& W = *findCell(x+0, y+1, z+0, 2);
							initCnt1(cell, atom, cell, 6);
							initCnt2(cell, atom, cell, 1);
							initCnt2(cell, atom, N, 0);
							initCnt2(cell, atom, N, 2);
							initCnt1(cell, atom, cell, 7);
							initCnt2(cell, atom, cell, 2);
							initCnt2(cell, atom, W, 0);
							initCnt2(cell, atom, W, 1);
							initCnt1(cell, atom, D, 4);
							initCnt2(cell, atom, D, 1);
							initCnt2(cell, atom, D, 2);
							initCnt2(cell, atom, cell, 0);
							initCnt1(cell, atom, D, 5);
							initCnt2(cell, atom, ND, 2);
							initCnt2(cell, atom, WD, 1);
							initCnt2(cell, atom, NW, 0);
							break;
						}
						case 4:
						{
							MCCell& SU = *findCell(x+-1, y+0, z+1, 2);
							MCCell& SE = *findCell(x+-1, y+-1, z+0, 2);
							MCCell& EU = *findCell(x+0, y+-1, z+1, 2);
							MCCell& U = *findCell(x+0, y+0, z+1, 2);
							MCCell& E = *findCell(x+0, y+-1, z+0, 2);
							MCCell& S = *findCell(x+-1, y+0, z+0, 2);
							initCnt1(cell, atom, cell, 1);
							initCnt2(cell, atom, cell, 6);
							initCnt2(cell, atom, E, 7);
							initCnt2(cell, atom, E, 5);
							initCnt1(cell, atom, cell, 2);
							initCnt2(cell, atom, cell, 7);
							initCnt2(cell, atom, S, 5);
							initCnt2(cell, atom, S, 6);
							initCnt1(cell, atom, U, 0);
							initCnt2(cell, atom, SU, 6);
							initCnt2(cell, atom, EU, 7);
							initCnt2(cell, atom, SE, 5);
							initCnt1(cell, atom, U, 3);
							initCnt2(cell, atom, U, 6);
							initCnt2(cell, atom, U, 7);
							initCnt2(cell, atom, cell, 5);
							break;
						}
						case 5:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 2);
							MCCell& U = *findCell(x+0, y+0, z+1, 2);
							MCCell& N = *findCell(x+1, y+0, z+0, 2);
							MCCell& WU = *findCell(x+0, y+1, z+1, 2);
							MCCell& NWU = *findCell(x+1, y+1, z+1, 2);
							MCCell& NU = *findCell(x+1, y+0, z+1, 2);
							MCCell& NW = *findCell(x+1, y+1, z+0, 2);
							initCnt1(cell, atom, N, 2);
							initCnt2(cell, atom, N, 7);
							initCnt2(cell, atom, N, 4);
							initCnt2(cell, atom, cell, 6);
							initCnt1(cell, atom, W, 1);
							initCnt2(cell, atom, W, 4);
							initCnt2(cell, atom, W, 6);
							initCnt2(cell, atom, cell, 7);
							initCnt1(cell, atom, U, 3);
							initCnt2(cell, atom, U, 6);
							initCnt2(cell, atom, U, 7);
							initCnt2(cell, atom, cell, 4);
							initCnt1(cell, atom, NWU, 0);
							initCnt2(cell, atom, WU, 6);
							initCnt2(cell, atom, NU, 7);
							initCnt2(cell, atom, NW, 4);
							break;
						}
						case 6:
						{
							MCCell& ED = *findCell(x+0, y+-1, z+-1, 2);
							MCCell& N = *findCell(x+1, y+0, z+0, 2);
							MCCell& ND = *findCell(x+1, y+0, z+-1, 2);
							MCCell& NE = *findCell(x+1, y+-1, z+0, 2);
							MCCell& D = *findCell(x+0, y+0, z+-1, 2);
							MCCell& E = *findCell(x+0, y+-1, z+0, 2);
							initCnt1(cell, atom, cell, 1);
							initCnt2(cell, atom, cell, 4);
							initCnt2(cell, atom, E, 7);
							initCnt2(cell, atom, E, 5);
							initCnt1(cell, atom, cell, 3);
							initCnt2(cell, atom, cell, 7);
							initCnt2(cell, atom, D, 4);
							initCnt2(cell, atom, D, 5);
							initCnt1(cell, atom, N, 0);
							initCnt2(cell, atom, NE, 7);
							initCnt2(cell, atom, ND, 4);
							initCnt2(cell, atom, ED, 5);
							initCnt1(cell, atom, N, 2);
							initCnt2(cell, atom, N, 7);
							initCnt2(cell, atom, N, 4);
							initCnt2(cell, atom, cell, 5);
							break;
						}
						case 7:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 2);
							MCCell& S = *findCell(x+-1, y+0, z+0, 2);
							MCCell& SW = *findCell(x+-1, y+1, z+0, 2);
							MCCell& SD = *findCell(x+-1, y+0, z+-1, 2);
							MCCell& D = *findCell(x+0, y+0, z+-1, 2);
							MCCell& WD = *findCell(x+0, y+1, z+-1, 2);
							initCnt1(cell, atom, cell, 2);
							initCnt2(cell, atom, cell, 4);
							initCnt2(cell, atom, S, 5);
							initCnt2(cell, atom, S, 6);
							initCnt1(cell, atom, cell, 3);
							initCnt2(cell, atom, cell, 6);
							initCnt2(cell, atom, D, 4);
							initCnt2(cell, atom, D, 5);
							initCnt1(cell, atom, W, 0);
							initCnt2(cell, atom, SW, 6);
							initCnt2(cell, atom, WD, 4);
							initCnt2(cell, atom, SD, 5);
							initCnt1(cell, atom, W, 1);
							initCnt2(cell, atom, W, 4);
							initCnt2(cell, atom, W, 6);
							initCnt2(cell, atom, cell, 5);
							break;
						}
					}


#endif
				}

				void CMCAnisotropic::etch(MCAtom& mcatom)
				{
					MCCell& cell = *mcatom.getCell();

					// TODO - replace this with FL_LOG!
					if (getenv("ETCH3D_DEBUG_STEP_INFO"))
					{
						Wml::Vector3d saneCellCoords;
						cout << "\nEtching atom #" << (Int32)mcatom.atomIndex << " in cell "<< (Int32)(cell.x-kHalfSize/4) << ", " << (Int32)(cell.y - kHalfSize/4) << ", " << (Int32)(cell.z - kHalfSize/4);
						printAtom("", cell, mcatom.atomIndex);
					}

					Uint32 x = cell.x;
					Uint32 y = cell.y;
					Uint32 z = cell.z;

					Int32 atom = mcatom.atomIndex;

#if CODEGEN
					<% NeighborCounts("decCnt1", "decCnt2", "1");
					%>
#else

					switch (atom)
					{
						case 0:
						{
							MCCell& ED = *findCell(x+0, y+-1, z+-1, 1);
							MCCell& SED = *findCell(x+-1, y+-1, z+-1, 1);
							MCCell& SE = *findCell(x+-1, y+-1, z+0, 1);
							MCCell& SD = *findCell(x+-1, y+0, z+-1, 1);
							MCCell& D = *findCell(x+0, y+0, z+-1, 1);
							MCCell& E = *findCell(x+0, y+-1, z+0, 1);
							MCCell& S = *findCell(x+-1, y+0, z+0, 1);
							decCnt1(cell, atom, S, 6);
							decCnt2(cell, atom, S, 1);
							decCnt2(cell, atom, S, 3);
							decCnt2(cell, atom, cell, 2);
							decCnt1(cell, atom, E, 7);
							decCnt2(cell, atom, E, 2);
							decCnt2(cell, atom, E, 3);
							decCnt2(cell, atom, cell, 1);
							decCnt1(cell, atom, D, 4);
							decCnt2(cell, atom, D, 1);
							decCnt2(cell, atom, D, 2);
							decCnt2(cell, atom, cell, 3);
							decCnt1(cell, atom, SED, 5);
							decCnt2(cell, atom, ED, 2);
							decCnt2(cell, atom, SD, 1);
							decCnt2(cell, atom, SE, 3);
							break;
						}
						case 1:
						{
							MCCell& NU = *findCell(x+1, y+0, z+1, 1);
							MCCell& U = *findCell(x+0, y+0, z+1, 1);
							MCCell& E = *findCell(x+0, y+-1, z+0, 1);
							MCCell& NE = *findCell(x+1, y+-1, z+0, 1);
							MCCell& N = *findCell(x+1, y+0, z+0, 1);
							MCCell& EU = *findCell(x+0, y+-1, z+1, 1);
							decCnt1(cell, atom, cell, 4);
							decCnt2(cell, atom, cell, 2);
							decCnt2(cell, atom, U, 0);
							decCnt2(cell, atom, U, 3);
							decCnt1(cell, atom, cell, 6);
							decCnt2(cell, atom, cell, 3);
							decCnt2(cell, atom, N, 0);
							decCnt2(cell, atom, N, 2);
							decCnt1(cell, atom, E, 7);
							decCnt2(cell, atom, E, 2);
							decCnt2(cell, atom, E, 3);
							decCnt2(cell, atom, cell, 0);
							decCnt1(cell, atom, E, 5);
							decCnt2(cell, atom, NE, 2);
							decCnt2(cell, atom, EU, 3);
							decCnt2(cell, atom, NU, 0);
							break;
						}
						case 2:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 1);
							MCCell& SU = *findCell(x+-1, y+0, z+1, 1);
							MCCell& SW = *findCell(x+-1, y+1, z+0, 1);
							MCCell& WU = *findCell(x+0, y+1, z+1, 1);
							MCCell& U = *findCell(x+0, y+0, z+1, 1);
							MCCell& S = *findCell(x+-1, y+0, z+0, 1);
							decCnt1(cell, atom, cell, 7);
							decCnt2(cell, atom, cell, 3);
							decCnt2(cell, atom, W, 0);
							decCnt2(cell, atom, W, 1);
							decCnt1(cell, atom, cell, 4);
							decCnt2(cell, atom, cell, 1);
							decCnt2(cell, atom, U, 0);
							decCnt2(cell, atom, U, 3);
							decCnt1(cell, atom, S, 5);
							decCnt2(cell, atom, SW, 1);
							decCnt2(cell, atom, SU, 3);
							decCnt2(cell, atom, WU, 0);
							decCnt1(cell, atom, S, 6);
							decCnt2(cell, atom, S, 1);
							decCnt2(cell, atom, S, 3);
							decCnt2(cell, atom, cell, 0);
							break;
						}
						case 3:
						{
							MCCell& NW = *findCell(x+1, y+1, z+0, 1);
							MCCell& ND = *findCell(x+1, y+0, z+-1, 1);
							MCCell& D = *findCell(x+0, y+0, z+-1, 1);
							MCCell& N = *findCell(x+1, y+0, z+0, 1);
							MCCell& WD = *findCell(x+0, y+1, z+-1, 1);
							MCCell& W = *findCell(x+0, y+1, z+0, 1);
							decCnt1(cell, atom, cell, 6);
							decCnt2(cell, atom, cell, 1);
							decCnt2(cell, atom, N, 0);
							decCnt2(cell, atom, N, 2);
							decCnt1(cell, atom, cell, 7);
							decCnt2(cell, atom, cell, 2);
							decCnt2(cell, atom, W, 0);
							decCnt2(cell, atom, W, 1);
							decCnt1(cell, atom, D, 4);
							decCnt2(cell, atom, D, 1);
							decCnt2(cell, atom, D, 2);
							decCnt2(cell, atom, cell, 0);
							decCnt1(cell, atom, D, 5);
							decCnt2(cell, atom, ND, 2);
							decCnt2(cell, atom, WD, 1);
							decCnt2(cell, atom, NW, 0);
							break;
						}
						case 4:
						{
							MCCell& SU = *findCell(x+-1, y+0, z+1, 1);
							MCCell& SE = *findCell(x+-1, y+-1, z+0, 1);
							MCCell& EU = *findCell(x+0, y+-1, z+1, 1);
							MCCell& U = *findCell(x+0, y+0, z+1, 1);
							MCCell& E = *findCell(x+0, y+-1, z+0, 1);
							MCCell& S = *findCell(x+-1, y+0, z+0, 1);
							decCnt1(cell, atom, cell, 1);
							decCnt2(cell, atom, cell, 6);
							decCnt2(cell, atom, E, 7);
							decCnt2(cell, atom, E, 5);
							decCnt1(cell, atom, cell, 2);
							decCnt2(cell, atom, cell, 7);
							decCnt2(cell, atom, S, 5);
							decCnt2(cell, atom, S, 6);
							decCnt1(cell, atom, U, 0);
							decCnt2(cell, atom, SU, 6);
							decCnt2(cell, atom, EU, 7);
							decCnt2(cell, atom, SE, 5);
							decCnt1(cell, atom, U, 3);
							decCnt2(cell, atom, U, 6);
							decCnt2(cell, atom, U, 7);
							decCnt2(cell, atom, cell, 5);
							break;
						}
						case 5:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 1);
							MCCell& U = *findCell(x+0, y+0, z+1, 1);
							MCCell& N = *findCell(x+1, y+0, z+0, 1);
							MCCell& WU = *findCell(x+0, y+1, z+1, 1);
							MCCell& NWU = *findCell(x+1, y+1, z+1, 1);
							MCCell& NU = *findCell(x+1, y+0, z+1, 1);
							MCCell& NW = *findCell(x+1, y+1, z+0, 1);
							decCnt1(cell, atom, N, 2);
							decCnt2(cell, atom, N, 7);
							decCnt2(cell, atom, N, 4);
							decCnt2(cell, atom, cell, 6);
							decCnt1(cell, atom, W, 1);
							decCnt2(cell, atom, W, 4);
							decCnt2(cell, atom, W, 6);
							decCnt2(cell, atom, cell, 7);
							decCnt1(cell, atom, U, 3);
							decCnt2(cell, atom, U, 6);
							decCnt2(cell, atom, U, 7);
							decCnt2(cell, atom, cell, 4);
							decCnt1(cell, atom, NWU, 0);
							decCnt2(cell, atom, WU, 6);
							decCnt2(cell, atom, NU, 7);
							decCnt2(cell, atom, NW, 4);
							break;
						}
						case 6:
						{
							MCCell& ED = *findCell(x+0, y+-1, z+-1, 1);
							MCCell& N = *findCell(x+1, y+0, z+0, 1);
							MCCell& ND = *findCell(x+1, y+0, z+-1, 1);
							MCCell& NE = *findCell(x+1, y+-1, z+0, 1);
							MCCell& D = *findCell(x+0, y+0, z+-1, 1);
							MCCell& E = *findCell(x+0, y+-1, z+0, 1);
							decCnt1(cell, atom, cell, 1);
							decCnt2(cell, atom, cell, 4);
							decCnt2(cell, atom, E, 7);
							decCnt2(cell, atom, E, 5);
							decCnt1(cell, atom, cell, 3);
							decCnt2(cell, atom, cell, 7);
							decCnt2(cell, atom, D, 4);
							decCnt2(cell, atom, D, 5);
							decCnt1(cell, atom, N, 0);
							decCnt2(cell, atom, NE, 7);
							decCnt2(cell, atom, ND, 4);
							decCnt2(cell, atom, ED, 5);
							decCnt1(cell, atom, N, 2);
							decCnt2(cell, atom, N, 7);
							decCnt2(cell, atom, N, 4);
							decCnt2(cell, atom, cell, 5);
							break;
						}
						case 7:
						{
							MCCell& W = *findCell(x+0, y+1, z+0, 1);
							MCCell& S = *findCell(x+-1, y+0, z+0, 1);
							MCCell& SW = *findCell(x+-1, y+1, z+0, 1);
							MCCell& SD = *findCell(x+-1, y+0, z+-1, 1);
							MCCell& D = *findCell(x+0, y+0, z+-1, 1);
							MCCell& WD = *findCell(x+0, y+1, z+-1, 1);
							decCnt1(cell, atom, cell, 2);
							decCnt2(cell, atom, cell, 4);
							decCnt2(cell, atom, S, 5);
							decCnt2(cell, atom, S, 6);
							decCnt1(cell, atom, cell, 3);
							decCnt2(cell, atom, cell, 6);
							decCnt2(cell, atom, D, 4);
							decCnt2(cell, atom, D, 5);
							decCnt1(cell, atom, W, 0);
							decCnt2(cell, atom, SW, 6);
							decCnt2(cell, atom, WD, 4);
							decCnt2(cell, atom, SD, 5);
							decCnt1(cell, atom, W, 1);
							decCnt2(cell, atom, W, 4);
							decCnt2(cell, atom, W, 6);
							decCnt2(cell, atom, cell, 5);
							break;
						}
					}
#endif

// Tons more code removed here ...